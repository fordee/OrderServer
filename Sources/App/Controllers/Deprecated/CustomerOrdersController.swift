//
//  CustomersOrderController.swift
//  
//
//  Created by John Forde on 21/07/22.
//
//
//import Foundation
//import Vapor
//
//struct CustomerOrdersController: RouteCollection {
//  func boot(routes: RoutesBuilder) throws {
//    let customerOrdersRoute = routes.grouped("api", "orders")
//    customerOrdersRoute.post(use: createHandler)
//    customerOrdersRoute.get(use: getAllHandler)
//    customerOrdersRoute.get(":orderID", use: getHandler)
//    customerOrdersRoute.get(":orderID", "resvervation", use: getReservationHandler)
//  }
//
//  func getAllHandler(_ req: Request) async throws -> [CustomerOrder] {
//    try await CustomerOrder.query(on: req.db).all()
//  }
//
//  func getHandler(_ req: Request) async throws -> CustomerOrder {
//    guard let customerOrder = try await CustomerOrder.find(req.parameters.get("orderID"), on: req.db) else {
//      throw Abort(.notFound)
//    }
//    return customerOrder
//  }
//
//  func getReservaionHandler(_ req: Request) async throws -> Reservation {
//    guard let customerOrder = try await CustomerOrder.find(req.parameters.get("orderID"), on: req.db) else {
//      throw Abort(.notFound)
//    }
//    return try await customerOrder.$reservation.get(on: req.db)
//  }
//
//  func createHandler(_ req: Request) async throws -> CustomerOrder {
//    let data = try req.content.decode(CreateCustomerCustomerOrderData.self)
//    let customerOrder = CustomerOrder(status: data.status, submittedTime: data.submittedTime, paid: data.paid, reservationID: data.reservationID)
//    try await customerOrder.save(on: req.db)
//    return customerOrder
//  }
//
//  func updateHandler(_ req: Request) async throws -> CustomerOrder {
//    let updatedCustomerOrder = try req.content.decode(CustomerOrder.self)
//    guard let customerOrder = try await CustomerOrder.find(req.parameters.get("orderID"), on: req.db) else {
//      throw Abort(.notFound)
//    }
//    customerOrder.status = updatedCustomerOrder.status
//    customerOrder.submittedTime = updatedCustomerOrder.submittedTime
//    customerOrder.deliveredTime = updatedCustomerOrder.deliveredTime
//    customerOrder.paid = updatedCustomerOrder.paid
//    try await customerOrder.save(on: req.db)
//    return customerOrder
//  }
//
//  func getReservationHandler(_ req: Request) async throws -> Reservation {
//    guard let customerOrder = try await CustomerOrder.find(req.parameters.get("orderID"), on: req.db) else {
//      throw Abort(.notFound)
//    }
//    return try await customerOrder.$reservation.get(on: req.db)
//  }
//
//}
//
