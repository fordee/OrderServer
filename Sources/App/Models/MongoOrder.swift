//
//  MongoOrder.swift
//  
//
//  Created by John Forde on 30/07/22.
//

import Vapor
import MongoDBVapor

protocol MongoIdentifiable {
  var _id: BSONObjectID? { get set }
}

enum OrderStatus: String, Codable {
  case submitted
  case cancelled
  case delivered
}

struct MongoOrder: Content, MongoIdentifiable {
  var _id: BSONObjectID?
  let reservationId: String
  let status: OrderStatus
  let paid: Bool
  let submittedTime: Date
  var deliveredTime: Date? = nil
  var items: [MongoOrderItems] = []
}

struct MongoOrderItems: Content {
  let product: MongoProduct
  let quantity: Int
  let price: Double
}

struct CreateMongoOrder: Codable {
  let reservationId: String
  let status: OrderStatus
  let paid: Bool
}

/// The structure of a status update request.
struct StatusUpdate: Codable {
  let status: OrderStatus
}

//struct AddOrderItem: Codable {
//  let items: [MongoOrderItems]
//}
