//
//  File.swift
//  
//
//  Created by John Forde on 21/07/22.
//

import Fluent


struct CreateCustomerOrder: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("customer_orders")
      .id()
      .field("status", .string, .required)
      .field("submitted_time", .datetime, .required)
      .field("delivered_time", .datetime)
      .field("paid", .bool, .required)
      .field("reservationID", .uuid, .required, .references("reservations", "id"))
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("customer_orders").delete()
  }
}
