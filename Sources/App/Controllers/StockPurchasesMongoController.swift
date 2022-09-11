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
    stockPurchasesRoutes.get(":_id", use: updateHandler)
    stockPurchasesRoutes.get(use: getAllHandler)
  }

  func createHandler(_ req: Request) async throws -> MongoStockPurchase {
    try await req.addStockPurchase()
  }

  func getAllHandler(_ req: Request) async throws -> [MongoStockPurchase] {
    try await req.findStockPurchases()
  }

  func updateHandler(_ req: Request) async throws -> Response {
    try await req.updateStockPurchase()
  }
}

extension Request {
  var stockPurchaseCollection: MongoCollection<MongoStockPurchase> {
    application.mongoDB.client.db("orderserver").collection("stockpurchases", withType: MongoStockPurchase.self)
  }

  func addStockPurchase() async throws -> MongoStockPurchase {
    let stockPurchase = try content.decode(MongoStockPurchase.self)
    _ = try await mongoInsert(stockPurchase, into: stockPurchaseCollection)
    //try await recalculateAveragePrice(stockPurchase: stockPurchase)
    return stockPurchase
  }

  func findStockPurchases() async throws -> [MongoStockPurchase] {
    try await stockPurchaseCollection.find().toArray()
  }

//  func recalculateAveragePrice(stockPurchase: MongoStockPurchase) async throws {
//    let objectIdFilter: BSONDocument = ["_id": .objectID(stockPurchase.productId)]
//    guard let product =  try await productCollection.findOne(objectIdFilter) else { throw Abort(.notFound) }
//    let totalQuantity = stockPurchase.quantity + product.stock
//    let weightedAveragePrice = ((product.averagePurchasePrice * Double(product.stock)) + (stockPurchase.price * Double(stockPurchase.quantity))) / Double(totalQuantity)
//    let update = MongoProduct(name: product.name,
//                              description: product.description,
//                              imagePath: product.imagePath,
//                              stock: totalQuantity,
//                              //averagePurchasePrice: weightedAveragePrice,
//                              sellingPrice: product.sellingPrice,
//                              bestByDate: product.bestByDate)
//    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
//    _ = try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: productCollection)
//  }

  func updateStockPurchase() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    let update = try content.decode(MongoStockPurchase.self)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: stockPurchaseCollection)
  }
}
