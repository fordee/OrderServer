//
//  File.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Fluent

struct CreateProduct: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("products")
      .id()
      .field("name", .string, .required)
      .field("description", .string, .required)
      .field("image_path", .string, .required)
      .field("price", .double, .required)
      .field("quantity", .int, .required)
      .field("average_purchase_price", .double, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("products").delete()
  }
}
