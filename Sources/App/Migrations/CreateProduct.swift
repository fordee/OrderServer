//
//  File.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Fluent

struct CreateProduct: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("product")
      .id()
      .field("name", .string, .required)
      .field("description", .string, .required)
      .field("image_path", .string, .required)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("product").delete()
  }
}
