//
//  CustomerPurchase.swift
//  
//
//  Created by John Forde on 8/07/22.
//

import Vapor
import Fluent

final class CustomerPurchase: Model {
  static let schema = "customer_purchases"

  @ID
  var id: UUID?

  @Parent(key: "customer_id")
  var customer: Customer

  @Field(key: "product_id")
  var productId: String

  @Field(key: "price")
  var price: Double

  @Field(key: "quantity")
  var quantity: Int

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  // When this Planet was last updated.
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(id: UUID? = nil, customerID: Customer.IDValue, productId: String, price: Double, quantity: Int) {
    self.id = id
    self.$customer.id = customerID
    self.productId = productId
    self.price = price
    self.quantity = quantity
  }

}

extension CustomerPurchase: Content {}

struct CreateCustomerPurchaseData: Content {
  let customerID: UUID
  let productId: String
  let price: Double
  let quantity: Int
}
