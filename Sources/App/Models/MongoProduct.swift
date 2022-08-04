//
//  File.swift
//  
//
//  Created by John Forde on 31/07/22.
//


import Vapor
import MongoDBVapor

struct MongoProduct: Content {
  var _id: BSONObjectID?
  var name: String
  var description: String
  var imagePath: String
  var stock: Int
  var averagePurchasePrice: Double
  var sellingPrice: Double
  var bestByDate: Date
}

//struct CreateMongoProduct: Codable {
//  let reservationId: String
//  let status: OrderStatus
//  let paid: Bool
//}

/// The structure of a status update request.
//struct StatusUpdate: Codable {
//  let status: OrderStatus
//}
//
//struct AddOrderItem: Codable {
//  let items: [MongoOrderItems]
//}

