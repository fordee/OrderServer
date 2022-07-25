//
//  CustomerPurchase.swift
//  
//
//  Created by John Forde on 8/07/22.
//

import Vapor
import Fluent

final class CustomerOrderItem: Model {
  static let schema = "customer_purchases"

  @ID
  var id: UUID?

  @Parent(key: "customerOrderID")
  var customerOrder: CustomerOrder

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

  init(id: UUID? = nil, productId: String, price: Double, quantity: Int, customerOrderID: CustomerOrder.IDValue) {
    self.id = id
    self.productId = productId
    self.price = price
    self.quantity = quantity
    self.$customerOrder.id = customerOrderID
  }

}

extension CustomerOrderItem: Content {}

struct CreateCustomerPurchaseData: Content {
  let productId: String
  let price: Double
  let quantity: Int
  let customerOrderID: UUID
}
