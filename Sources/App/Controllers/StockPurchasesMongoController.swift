//
//  File.swift
//  
//
//  Created by John Forde on 21/08/22.
//

import Foundation
import Vapor
import MongoDBVapor
import Models

struct StockPurchasesMongoController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let stockPurchasesRoutes = routes.grouped("api", "mongo", "stockpurchases")
    stockPurchasesRoutes.post(use: createHandler)
    stockPurchasesRoutes.get(use: getAllHandler)
  }

  func createHandler(_ req: Request) async throws -> MongoStockPurchase {
    try await req.addStockPurchase()
  }

  func getAllHandler(_ req: Request) async throws -> [MongoStockPurchase] {
    try await req.findStockPurchases()
  }
}

extension Request {
  var stockPurchaseCollection: MongoCollection<MongoStockPurchase> {
    application.mongoDB.client.db("orderserver").collection("stockpurchases", withType: MongoStockPurchase.self)
  }

  func addStockPurchase() async throws -> MongoStockPurchase {
    let stockPurchase = try content.decode(MongoStockPurchase.self)
    let newStockPurchase = try await mongoInsert(stockPurchase, into: stockPurchaseCollection)
    print(newStockPurchase)
    //try await recalculateAveragePrice(stockPurchase: stockPurchase)

    // Get product stock levels and add this to the total. TODO: Later have a resync function if required.

    let objectIdFilter: BSONDocument =  ["_id": .objectID(stockPurchase.productId)]
    guard let product =  try await productCollection.findOne(objectIdFilter) else {
      throw Abort(.notFound)
    }
    let update = MongoProduct(name: product.name,
                              description: product.description,
                              imagePath: product.imagePath,
                              stock: product.stock + stockPurchase.quantity, // Add purcahse quantity to stock levels.
                              sellingPrice: product.sellingPrice,
                              bestByDate: product.bestByDate)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
    let result = try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: productCollection)
    print(result)
    return newStockPurchase
  }

  func findStockPurchases() async throws -> [MongoStockPurchase] {
    try await stockPurchaseCollection.find().toArray()
  }

}
