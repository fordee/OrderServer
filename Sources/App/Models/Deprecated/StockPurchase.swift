//
//  File.swift
//  
//
//  Created by John Forde on 29/06/22.
//

//import Vapor
//import Fluent
//
//final class StockPurchase: Model {
//  static let schema = "stock_purchases"
//
//  @ID
//  var id: UUID?
//
//  @Field(key: "product_id")
//  var productId: UUID
//
//  @Field(key: "price")
//  var price: Double
//
//  @Field(key: "quantity")
//  var quantity: Int
//
//  @Timestamp(key: "created_at", on: .create)
//  var createdAt: Date?
//
//  // When this Planet was last updated.
//  @Timestamp(key: "updated_at", on: .update)
//  var updatedAt: Date?
//
//  init() {}
//
//  init(id: UUID? = nil, productId: UUID, price: Double, quantity: Int) {
//    self.id = id
//    self.productId = productId
//    self.price = price
//    self.quantity = quantity
//  }
//
//}
//
//extension StockPurchase: Content {}
//
