//
//  File.swift
//  
//
//  Created by John Forde on 29/06/22.
//

import Foundation
import Fluent

struct CreateStockPurchase: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("stock_purchases")
      .id()
      .field("product_id", .string, .required)
      .field("price", .double, .required)
      .field("quantity", .int, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("stock_purchases").delete()
  }
}
