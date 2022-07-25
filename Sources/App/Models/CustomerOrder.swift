//
//  CustomerOrder.swift
//  
//
//  Created by John Forde on 21/07/22.
//

import Vapor
import Fluent

final class CustomerOrder: Model {
  static let schema = "customer_orders"

  @ID
  var id: UUID?

  @Field(key: "status")
  var status: String

  @Field(key: "submitted_time")
  var submittedTime: Date

  @Field(key: "delivered_time")
  var deliveredTime: Date?

  @Field(key: "paid")
  var paid: Bool

  @Parent(key: "reservationID")
  var reservation: Reservation

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  // When this Planet was last updated.
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(id: UUID? = nil, status: String, submittedTime: Date, deliveredTime: Date? = nil, paid: Bool, reservationID: Reservation.IDValue, createdAt: Date? = nil, updatedAt: Date? = nil) {
    self.id = id
    self.status = status
    self.submittedTime = submittedTime
    self.deliveredTime = deliveredTime
    self.paid = paid
    self.$reservation.id = reservationID
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

}

extension CustomerOrder: Content {}

struct CreateCustomerCustomerOrderData: Content {
  let status: String
  let submittedTime: Date
  let deliveredTime: Date?
  let paid: Bool
  let reservationID: UUID
}

//struct CreateCustomerCustomerOrderData: Content {
//  let customerID: UUID
//  let productId: String
//  let price: Double
//  let quantity: Int
//}

