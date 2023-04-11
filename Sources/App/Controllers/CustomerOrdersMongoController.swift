//
//  CustomerOrdersMongoController.swift
//  
//
//  Created by John Forde on 30/07/22.
//

import Foundation
import Vapor
import MongoDBVapor
import Models
import APNS

struct CustomerOrdersMongoController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let customerOrdersRoute = routes.grouped("api", "mongo", "orders")
    customerOrdersRoute.post(use: createHandler)
    customerOrdersRoute.get(use: getAllHandler)
    customerOrdersRoute.get("order", ":_id", use: getOrderByOrderId)
    customerOrdersRoute.get(":reservationId", ":statusString", use: getOrderByReservationId)
    customerOrdersRoute.patch(":_id", "updateStatus", use: updateStatusHandler)
    customerOrdersRoute.patch(":_id", "addOrderItem", use: addOrderItem)
    customerOrdersRoute.patch(":_id", "updateItems", use: updateItems)
    customerOrdersRoute.patch(":_id", "updateStatusItems", use: updateStatusItemsHandler)
//    customerOrdersRoute.get(":orderID", use: getHandler)
//    customerOrdersRoute.get(":orderID", "resvervation", use: getReservationHandler)
  }

  func addOrderItem(_ req: Request) async throws -> Response {
    try await req.addOrderItem()
  }

  func getOrderByOrderId(_ req: Request) async throws -> MongoOrder {
    try await req.findOrder()
  }

  func getAllHandler(_ req: Request) async throws -> [MongoOrder] {
    let headerToken = req.headers["Authorization"].first
    if !AuthController.authorize(token: headerToken) {
      throw Abort(.unauthorized)
    }
    guard let token = AuthController.token, let headerToken = req.headers["Authorization"].first, "BEARER \(token)" == "\(headerToken)" else {
      throw Abort(.unauthorized)
    }
    let fred = try await req.findOrders()//CustomerOrder.query(on: req.db).all()
    return fred
  }

  func getOrderByReservationId(_ req: Request) async throws -> [MongoOrder] {
    let reservationId = try req.getParameterString(parameterName: "reservationId")
    let statusString = try req.getParameterString(parameterName: "statusString")
    print("statusString: \(statusString)")
    let statusArray = getStatusArray(from: statusString)
    print("statusArray: \(statusArray)")
    return try await req.findOrders(by: reservationId, statuses: statusArray )
  }

  func getStatusArray(from statusString: String) -> [String] {
    let statusArray = statusString.components(separatedBy: ",")
    return statusArray
  }

  func createHandler(_ req: Request) async throws -> MongoOrder {
    try await req.addOrder()
  }

  func updateStatusHandler(_ req: Request) async throws -> Response {
    try await req.updateStatus()
  }

  func updateItems(_ req: Request) async throws -> Response {
    try await req.updateItems(req)
  }

  func updateStatusItemsHandler(_ req: Request) async throws -> Response {
    try await req.updateStatusItems()
  }
}

extension Request {
  var orderCollection: MongoCollection<MongoOrder> {
    application.mongoDB.client.db("orderserver").collection("orders", withType: MongoOrder.self)
  }

  func addOrder() async throws -> MongoOrder {
    let newOrder = try content.decode(MongoOrder.self)
    //let newOrder = MongoOrder(reservationId: createOrder.reservationId, status: createOrder.status, paid: false, submittedTime: Date(), items: [])
    return try await mongoInsert(newOrder, into: orderCollection)
  }

  func findOrders() async throws -> [MongoOrder] {
    return try await orderCollection.find().toArray()
  }

  func findOrder() async throws -> MongoOrder {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    guard let order = try await orderCollection.find(objectIdFilter).next() else {
      throw Abort(.notFound)
    }
    return order
  }

  func findOrders(by reservationId: String, statuses: [String]) async throws -> [MongoOrder] {
    let filter: BSONDocument = ["reservationId": .string(reservationId), "$or": .array(createOrQuery(statusArray: statuses))]
    return try await orderCollection.find(filter).toArray()
  }

  func createOrQuery(statusArray: [String]) -> [BSON] {
    var resultArray: [BSON] = []
    for status in statusArray {
      let element: BSON = ["status": .string(status)]
      resultArray.append(element)
    }
    return resultArray
  }

  func updateStatus() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")

    let statusUpdate = try content.decode(StatusUpdate.self)
    //print(update)
    let updateDocument: BSONDocument
    if statusUpdate.status == .delivered {
      let statusDeliveredUpdate = StatusDeliveredTimeUpdate(status: statusUpdate.status)
      updateDocument = ["$set": .document(try BSONEncoder().encode(statusDeliveredUpdate))]
    } else {
      updateDocument = ["$set": .document(try BSONEncoder().encode(statusUpdate))]
    }

    if statusUpdate.status == .cancelled {
      let tokens = try await findTokens()

      let alert = APNSwiftAlert(title: "Order Cancelled", body: "Order has been cancelled.")

      for token in tokens {
        print("token: \(token.token)")
        _ = apns.send(alert, to: token.token)
      }
    }

    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

  func updateStatusItems() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")

    let statusUpdate = try content.decode(StatusItemsUpdate.self)
    //print(update)
    let updateDocument: BSONDocument
    if statusUpdate.status == .delivered {
      let statusDeliveredUpdate = StatusDeliveredTimeUpdate(status: statusUpdate.status)
      updateDocument = ["$set": .document(try BSONEncoder().encode(statusDeliveredUpdate))]
    } else {
      updateDocument = ["$set": .document(try BSONEncoder().encode(statusUpdate))]

      if statusUpdate.status == .submitted {
        let tokens = try await findTokens()

        let alert = APNSwiftAlert(title: "Order Received", body: "Order for \(statusUpdate.items.count) items received.")

        for token in tokens {
          print("token: \(token.token)")
          _ = apns.send(alert, to: token.token)
        }
      }
    }

    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

  func addOrderItem() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    let update = try content.decode(MongoOrderItem.self)
    let updateDocument: BSONDocument = ["$push": .document(try BSONEncoder().encode(["items": update]))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

  func updateItems(_ req: Request) async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    let statusItemsUpdate = try content.decode(Array<MongoOrderItem>.self)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(statusItemsUpdate))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

  func validate(items: [MongoOrderItem], for req: Request) async throws -> String? {
    var errors: [String] = []
    let products = try await req.findProducts()
    for item in items {
      if let product = products.first(where: { product in
        return product._id == item.product.id
      }) {
        print("Found: \(item.product.id!) stock: \(product.stock), quantity: \(item.quantity)")
        if product.stock < item.quantity {
          errors.append("For \(product.name), not enough stock (\(product.stock)) to satisfy your request (\(item.quantity)).")
        }
      }
      if errors.isEmpty { return nil } else { return errors.joined(separator: " ") }
    }
    return nil
  }

}

struct StatusFilter: Codable {
  let statuses: [OrderStatus]
}

struct WebOrderArrays: Codable {
  let status: String
  let productIds: [String]
  let quantities: [Int]
  let prices: [Double]
}

public struct StatusItemsUpdate: Codable {
  public let status: OrderStatus
  public let items: [MongoOrderItem]
  public let paymentMethod: PaymentMethod

  public init(status: OrderStatus, items: [MongoOrderItem], paymentMethod: String) {
    self.status = status
    self.items = items
    self.paymentMethod = PaymentMethod(rawValue: paymentMethod) ?? .cash
  }
}

public struct StatusUpdate: Codable {
  public let status: OrderStatus
}

public struct StatusDeliveredTimeUpdate: Codable {
  public let status: OrderStatus
  public var deliveredTime = Date()
}

