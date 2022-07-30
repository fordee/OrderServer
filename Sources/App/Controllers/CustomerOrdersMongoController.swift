//
//  File.swift
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
//    customerOrdersRoute.patch(":name", use: updateHandler)
//    customerOrdersRoute.get(":orderID", use: getHandler)
//    customerOrdersRoute.get(":orderID", "resvervation", use: getReservationHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [MongoOrder] {
    try await req.findOrders()//CustomerOrder.query(on: req.db).all()
  }

  func createHandler(_ req: Request) async throws -> Response {
    try await req.addOrder()

  }

  func updateHandler(_ req: Request) async throws -> Response {
    try await req.updateKitten()
  }

}

extension Request {
  var orderCollection: MongoCollection<MongoOrder> {
    self.application.mongoDB.client.db("orderserver").collection("orders", withType: MongoOrder.self)
  }

  func addOrder() async throws -> Response {
    let createOrder = try content.decode(CreateMongoOrder.self)
    let newOrder = MongoOrder(reservationId: createOrder.reservationId, status: createOrder.status, paid: false, submittedTime: Date.now)
    do {
      let fred = try await orderCollection.insertOne(newOrder)
      print(fred?.insertedID)
      return Response(status: .created)
    } catch {
      // Give a more helpful error message in case of a duplicate key error.
      if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
        throw Abort(.conflict, reason: "Orderfor: \(newOrder.reservationId) already exists!")
      }
      throw Abort(.internalServerError, reason: "Failed to save new order: \(error)")
    }
    //return Response(status: .created)
  }

  func findOrders() async throws -> [MongoOrder] {
    do {
      return try await orderCollection.find().toArray()
    } catch {
      throw Abort(.internalServerError, reason: "Failed to load orders: \(error)")
    }
  }

//  func findKittens() async throws -> [Kitten] {
//    do {
//      return try await self.orderCollection.find().toArray()
//    } catch {
//      throw Abort(.internalServerError, reason: "Failed to load kittens: \(error)")
//    }
//  }
//
//  func addKitten() async throws -> Response {
//
//    var newKitten = try content.decode(Kitten.self)
//    newKitten.lastUpdateTime = Date()
//    do {
//      try await orderCollection.insertOne(newKitten)
//      return Response(status: .created)
//    } catch {
//      // Give a more helpful error message in case of a duplicate key error.
//      if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
//        throw Abort(.conflict, reason: "A kitten with the name \(newKitten.name) already exists!")
//      }
//      throw Abort(.internalServerError, reason: "Failed to save new kitten: \(error)")
//    }
//  }

  /// Constructs a document using the name from this request which can be used a filter for MongoDB
  /// reads/updates/deletions.
  func getNameFilter() throws -> BSONDocument {
    // We only call this method from request handlers that have name parameters so the value
    // will always be available.
    guard let name = self.parameters.get("name") else {
      throw Abort(.internalServerError, reason: "Request unexpectedly missing name parameter")
    }
    return ["name": .string(name)]
  }


  func updateKitten() async throws -> Response {
    let nameFilter = try self.getNameFilter()
    // Parse the update data from the request.
    let update = try self.content.decode(KittenUpdate.self)
    /// Create a document using MongoDB update syntax that specifies we want to set a field.
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]

    do {
      // since we aren't using an unacknowledged write concern we can expect updateOne to return a non-nil result.
      guard let result = try await self.orderCollection.updateOne(
        filter: nameFilter,
        update: updateDocument
      ) else {
        throw Abort(.internalServerError, reason: "Unexpectedly nil response from database")
      }
      guard result.matchedCount == 1 else {
        throw Abort(.notFound, reason: "No kitten with matching name")
      }
      return Response(status: .ok)
    } catch {
      throw Abort(.internalServerError, reason: "Failed to update kitten: \(error)")
    }
  }
}
