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
    let customerPurchase = CustomerOrderItem(productId: data.productId, price: data.price, quantity: data.quantity, customerOrderID: data.customerOrderID)
    try await customerPurchase.save(on: req.db)
    return customerPurchase
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
}
