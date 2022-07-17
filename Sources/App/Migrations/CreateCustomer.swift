//
//  CreateCustomer.swift
//  
//
//  Created by John Forde on 9/07/22.
//

import Fluent

struct CreateCustomer: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("customers")
      .id()
      .field("username", .string, .required)
      .field("first_name", .string, .required)
      .field("last_name", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("customers").delete()
  }
}

