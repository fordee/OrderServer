//
//  File.swift
//  
//
//  Created by John Forde on 30/07/22.
//

import Vapor
import MongoDBVapor

enum OrderStatus: String, Codable {
  case submitted
  case cancelled
  case delivered
}

struct MongoOrder: Content {
  var _id: BSONObjectID?
  let reservationId: String
  let status: OrderStatus
  let paid: Bool
  let submittedTime: Date
  var deliveredTime: Date? = nil
  var items: [MongoOrderItems] = []
}

struct MongoOrderItems: Content {
  let productId: String
  let quantity: Int
  let price: Double
}

struct CreateMongoOrder: Codable {
  let reservationId: String
  let status: OrderStatus
  let paid: Bool
}
