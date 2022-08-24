//
//  CustomersController.swift
//  
//
//  Created by John Forde on 10/07/22.
//

//import Foundation
//import Vapor
//
//struct CustomersController: RouteCollection {
//  func boot(routes: RoutesBuilder) throws {
//    let customersRoute = routes.grouped("api", "customers")
//    customersRoute.post(use: createHandler)
//    customersRoute.get(use: getAllHandler)
//    customersRoute.get(":customerID", use: getHandler)
//  }
//
//  func getAllHandler(_ req: Request) async throws -> [Customer] {
//    try await Customer.query(on: req.db).all()
//  }
//
//  func getHandler(_ req: Request) async throws -> Customer {
//    guard let customer = try await Customer.find(req.parameters.get("customerID"), on: req.db) else {
//      throw Abort(.notFound)
//    }
//    return customer
//  }
//
//  func createHandler(_ req: Request) async throws -> Customer {
//    let customer = try req.content.decode(Customer.self)
//    try await customer.save(on: req.db)
//    return customer
//  }
//
//
//}
