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

struct CustomerOrdersMongoController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let customerOrdersRoute = routes.grouped("api", "mongo", "orders")
    customerOrdersRoute.post(use: createHandler)
    customerOrdersRoute.get(use: getAllHandler)
    customerOrdersRoute.get(":reservationId", ":statusString", use: getOrderByReservationId)
    customerOrdersRoute.patch(":_id", "updateStatus", use: updateStatusHandler)
    customerOrdersRoute.patch(":_id", "addOrderItem", use: addOrderItem)
    customerOrdersRoute.patch(":_id", "updateStatusItems", use: updateStatusItemsHandler)
//    customerOrdersRoute.get(":orderID", use: getHandler)
//    customerOrdersRoute.get(":orderID", "resvervation", use: getReservationHandler)
  }

  func addOrderItem(_ req: Request) async throws -> Response {
    try await req.addOrderItem()
  }

  func getAllHandler(_ req: Request) async throws -> [MongoOrder] {
    let headerToken = req.headers["Authorization"].first
    if !AuthController.authorize(token: headerToken) {
      throw Abort(.unauthorized)
    }
//    guard let token = AuthController.token, let headerToken = req.headers["Authorization"].first, "BEARER \(token)" == "\(headerToken)" else {
//      throw Abort(.unauthorized)
//    }

    return try await req.findOrders()//CustomerOrder.query(on: req.db).all()
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

  func updateStatusItemsHandler(_ req: Request) async throws -> Response {
    try await req.updateItems(req)
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
    print(objectIdFilter)
    print(body)
    let update = try content.decode(StatusUpdate.self)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
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
    let statusItemsUpdate = try content.decode(StatusItemsUpdate.self)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(statusItemsUpdate))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

  func updateStatusItems(_ req: Request) async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    let webOrderItem = try content.decode(WebOrderArrays.self)

    var items: [MongoOrderItem] = []
    for (index, id) in zip(webOrderItem.productIds.indices, webOrderItem.productIds) {
      let pid: BSONDocument = ["_id": .objectID(try BSONObjectID(id))]
      if let product = try? await productCollection.findOne(pid) {
        let item = MongoOrderItem(product: product, quantity: webOrderItem.quantities[index], price: webOrderItem.prices[index])
        items.append(item)
      }
    }
    // Perform validations
    if let m = try await validate(items: items, for: req), let message = m.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
      print("message: \(message)")
      return Response(status: .custom(code: 408, reasonPhrase: message))
    }
    let statusItemsUpdate = StatusItemsUpdate(status: OrderStatus(rawValue: webOrderItem.status) ?? .open, items: items)
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

  public init(status: OrderStatus, items: [MongoOrderItem]) {
    self.status = status
    self.items = items
  }
}

