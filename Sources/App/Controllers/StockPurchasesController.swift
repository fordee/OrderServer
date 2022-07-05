//
//  SwiftUIView.swift
//  
//
//  Created by John Forde on 29/06/22.
//

import Vapor
import Fluent

struct StockPurchasesController: RouteCollection {
  func boot(routes: Vapor.RoutesBuilder) throws {
    let stockPurchasesRoutes = routes.grouped("api", "stockpurchases")
    stockPurchasesRoutes.post(use: createHandler)
    stockPurchasesRoutes.get(use: getAllHandler)
  }

  func createHandler(_ req: Request) async throws -> StockPurchase {
    let stockPurchase = try req.content.decode(StockPurchase.self)
    print("stockPurchase: \(stockPurchase.productId)")
    try await stockPurchase.save(on: req.db)
    try await recalculateAveragePrice(stockPurchase: stockPurchase, req: req)

    return stockPurchase
  }

  func updateHandler(_ req: Request) async throws -> StockPurchase {
    let updatedStockPurchase = try req.content.decode(StockPurchase.self)
    guard let stockPurchase = try await StockPurchase.find(req.parameters.get("stockPurchaseID"), on: req.db) else {
      throw Abort(.notFound)
    }
    
    stockPurchase.productId = updatedStockPurchase.productId
    stockPurchase.price = updatedStockPurchase.price
    stockPurchase.quantity = updatedStockPurchase.quantity
    try await stockPurchase.save(on: req.db)
    try await recalculateAveragePrice(stockPurchase: stockPurchase, req: req)

    return stockPurchase
  }

  func getAllHandler(_ req: Request) async throws -> [StockPurchase] {
    try await StockPurchase.query(on: req.db).all()
  }

  func recalculateAveragePrice(stockPurchase: StockPurchase, req: Request) async throws {
    guard let product = try await Product.find(stockPurchase.productId, on: req.db) else { throw Abort(.notFound) }
    let totalQuantity = stockPurchase.quantity + product.quantity
    let weightedAveragePrice = ((product.averagePurchasePrice * Double(product.quantity)) + (stockPurchase.price * Double(stockPurchase.quantity))) / Double(totalQuantity)
    product.averagePurchasePrice = weightedAveragePrice
    product.quantity = totalQuantity
    try await product.save(on: req.db)
  }

}

