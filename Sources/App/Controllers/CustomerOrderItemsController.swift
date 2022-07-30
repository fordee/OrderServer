//
//  CustomerPurchasesController.swift
//  
//
//  Created by John Forde on 10/07/22.
//

import Vapor

struct CustomerOrderItemsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let customerOrderItemsRoutes = routes.grouped("api", "customerOrderItems")
    customerOrderItemsRoutes.post(use: createHandler)
    customerOrderItemsRoutes.get(use: getAllHandler)
    customerOrderItemsRoutes.get(":orderItemID", use: getHandler)
    customerOrderItemsRoutes.get(":orderItemID", "customerOrder", use: getCustomerOrderHandler)
  }

  func createHandler(_ req: Request) async throws -> CustomerOrderItem {

    let data = try req.content.decode(CreateCustomerPurchaseData.self)

    if let itemId = try await getFirstExistingItemOnOrder(req, productId: data.productId, productPrice: data.price, orderId: data.customerOrderID) { // Item with same product and price exists on order
      guard let item = try await CustomerOrderItem.find(itemId, on: req.db) else {
        throw Abort(.notFound)
      }
      item.quantity += data.quantity
      try await item.save(on: req.db)
      return item
    } else {
      let customerOrderItem = CustomerOrderItem(productId: data.productId, price: data.price, quantity: data.quantity, customerOrderID: data.customerOrderID)
      try await customerOrderItem.save(on: req.db)
      return customerOrderItem
    }
  }

  func getAllHandler(_ req: Request) async throws -> [CustomerOrderItem] {
    try await CustomerOrderItem.query(on: req.db).all()
  }

  func getHandler(_ req: Request) async throws -> CustomerOrderItem {
    guard let customerOrderItem = try await CustomerOrderItem.find(req.parameters.get("orderItemID"), on: req.db) else {
      throw Abort(.notFound)
    }
    return customerOrderItem
  }

  func getCustomerOrderHandler(_ req: Request) async throws -> CustomerOrder {
    guard let customerOrderItem = try await CustomerOrderItem.find(req.parameters.get("orderItemID"), on: req.db) else {
      throw Abort(.notFound)
    }
    //return customerOrder
    return try await customerOrderItem.$customerOrder.get(on: req.db)
  }

  func getFirstExistingItemOnOrder(_ req: Request, productId: String, productPrice: Double, orderId: UUID) async throws -> UUID? {
    let items = try await CustomerOrderItem.query(on: req.db).all()
    for item in items {
      if item.productId == productId && item.price == productPrice {
        return item.id
      }
    }
    return nil
  }
}
