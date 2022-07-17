//
//  CustomerPurchasesController.swift
//  
//
//  Created by John Forde on 10/07/22.
//

import Vapor

struct CustomerPurchasesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let customerPurchasesRoutes = routes.grouped("api", "customerpurchases")
    customerPurchasesRoutes.post(use: createHandler)
    customerPurchasesRoutes.get(use: getAllHandler)
  }

  func createHandler(_ req: Request) async throws -> CustomerPurchase {
    let data = try req.content.decode(CreateCustomerPurchaseData.self)
    let customerPurchase = CustomerPurchase(customerID: data.customerID, productId: data.productId, price: data.price, quantity: data.quantity)
    try await customerPurchase.save(on: req.db)
    return customerPurchase
  }

  func getAllHandler(_ req: Request) async throws -> [CustomerPurchase] {
    try await CustomerPurchase.query(on: req.db).all()
  }


}
