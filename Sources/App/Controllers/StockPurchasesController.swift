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
    // TODO: Recalculate product's average price
    try await recalculateAveragePrice(productId: stockPurchase.productId, req: req)
    try await newRealculateAveragePrice(stockPurchase: stockPurchase, req: req)
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
    // TODO: Recalculate product's average price
    try await recalculateAveragePrice(productId: stockPurchase.productId, req: req)
    try await newRealculateAveragePrice(stockPurchase: stockPurchase, req: req)
    return stockPurchase
  }

  func getAllHandler(_ req: Request) async throws -> [StockPurchase] {
    try await StockPurchase.query(on: req.db).all()
  }

  func recalculateAveragePrice(productId: UUID, req: Request) async throws {
    let purchases = try await StockPurchase.query(on: req.db)
      .all()

    let filteredPurchases = purchases.filter{ purchase in
      purchase.productId == productId
    }
    print("puchases.count: \(purchases.count), filtered.count: \(filteredPurchases.count)")
    let averagePrices = filteredPurchases.compactMap { purchase in
      purchase.price * Double(purchase.quantity)
    }

    print("average prices count \(averagePrices.count) purchases count \(purchases.count)")

    let totalQuantity = filteredPurchases.reduce(0, { sum, purchase in
      sum + purchase.quantity
    })

    let weightedAveragePrice = averagePrices.reduce(0.0, { sum, price in
      sum + price
    }) / Double(totalQuantity)
    print("weighted average price: \(weightedAveragePrice)")
    guard let product = try await Product.find(productId, on: req.db) else {
      throw Abort(.notFound)
    }
    product.price = weightedAveragePrice
    product.quantity = totalQuantity
    try await product.save(on: req.db)
  }

  func newRealculateAveragePrice(stockPurchase: StockPurchase, req: Request) async throws {
    guard let product = try await Product.find(stockPurchase.productId, on: req.db) else {
      throw Abort(.notFound)
    }

    let totalQuantity = Double(stockPurchase.quantity + product.quantity)
    let weightedAveragePrice = ((product.price * Double(product.quantity)) + (stockPurchase.price * Double(stockPurchase.quantity))) / totalQuantity
    print("new weighted average price: \(weightedAveragePrice)")
  }

}

