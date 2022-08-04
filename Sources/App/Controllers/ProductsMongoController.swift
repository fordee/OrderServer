//
//  File.swift
//  
//
//  Created by John Forde on 31/07/22.
//

import Foundation
import Vapor
import MongoDBVapor

struct ProductsMongoController : RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let productsRoute = routes.grouped("api", "mongo", "products")
    productsRoute.post(use: createHandler)
    productsRoute.get(use: getAllHandler)
   // productsRoute.patch(":_id", "updateStatus", use: updateStatusHandler)
   // productsRoute.patch(":_id", "addOrderItem", use: addOrderItem)
  }

  func getAllHandler(_ req: Request) async throws -> [MongoProduct] {
    try await req.findProducts()
  }

  func createHandler(_ req: Request) async throws -> MongoProduct {
    try await req.addProduct()
  }

//  func updateStatusHandler(_ req: Request) async throws -> Response {
//    try await req.updateStatus()
//  }

//  func addOrderItem(_ req: Request) async throws -> Response {
//    try await req.addOrderItem()
//  }

}

extension Request {
  var productCollection: MongoCollection<MongoProduct> {
    application.mongoDB.client.db("orderserver").collection("products", withType: MongoProduct.self)
  }

  func findProducts() async throws -> [MongoProduct] {
    try await productCollection.find().toArray()
  }

  func addProduct() async throws -> MongoProduct {
    var product = try content.decode(MongoProduct.self)

    do {
      let result = try await productCollection.insertOne(product)
      product._id = result?.insertedID.objectIDValue

      return product
    } catch {
      // Give a more helpful error message in case of a duplicate key error.
      if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
        throw Abort(.conflict, reason: "Product for: \(product.name) already exists!")
      }
      throw Abort(.internalServerError, reason: "Failed to save new product: \(error)")
    }
  }

}
