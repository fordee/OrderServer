//
//  CustomerOrdersMongoController.swift
//  
//
//  Created by John Forde on 30/07/22.
//

import Foundation
import Vapor
import MongoDBVapor

struct CustomerOrdersMongoController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let customerOrdersRoute = routes.grouped("api", "mongo", "orders")
    customerOrdersRoute.post(use: createHandler)
    customerOrdersRoute.get(use: getAllHandler)
    customerOrdersRoute.patch(":_id", "updateStatus", use: updateStatusHandler)
    customerOrdersRoute.patch(":_id", "addOrderItem", use: addOrderItem)
//    customerOrdersRoute.patch(":name", use: updateHandler)
//    customerOrdersRoute.get(":orderID", use: getHandler)
//    customerOrdersRoute.get(":orderID", "resvervation", use: getReservationHandler)
  }

  func addOrderItem(_ req: Request) async throws -> Response {
    try await req.addOrderItem()
  }

  func getAllHandler(_ req: Request) async throws -> [MongoOrder] {
    try await req.findOrders()//CustomerOrder.query(on: req.db).all()
  }

  func createHandler(_ req: Request) async throws -> MongoOrder {
    try await req.addOrder()
  }

  func updateStatusHandler(_ req: Request) async throws -> Response {
    try await req.updateStatus()
  }

}

extension Request {
  var orderCollection: MongoCollection<MongoOrder> {
    application.mongoDB.client.db("orderserver").collection("orders", withType: MongoOrder.self)
  }

  func addOrder() async throws -> MongoOrder {
    let createOrder = try content.decode(CreateMongoOrder.self)
    let newOrder = MongoOrder(reservationId: createOrder.reservationId, status: createOrder.status, paid: false, submittedTime: Date.now)
    return try await mongoInsert(newOrder, into: orderCollection)
  }

  func findOrders() async throws -> [MongoOrder] {
    return try await orderCollection.find().toArray()
  }

  func updateStatus() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    print(objectIdFilter)
    let update = try content.decode(StatusUpdate.self)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

  func addOrderItem() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    let update = try content.decode(MongoOrderItems.self)
    let updateDocument: BSONDocument = ["$push": .document(try BSONEncoder().encode(["items": update]))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: orderCollection)
  }

}
