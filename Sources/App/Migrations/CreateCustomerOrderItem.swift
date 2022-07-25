//
//  File.swift
//  
//
//  Created by John Forde on 9/07/22.
//

import Vapor
import Fluent

struct CreateCustomerOrderItem: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("customer_purchases")
      .id()
      .field("customerOrderID", .uuid, .required, .references("customer_orders", "id"))
      .field("product_id", .string, .required)
      .field("price", .double, .required)
      .field("quantity", .int, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("customer_purchases").delete()
  }
}
