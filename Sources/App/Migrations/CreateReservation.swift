//
//  CreateReservation.swift
//  
//
//  Created by John Forde on 19/07/22.
//

import Fluent

struct CreateReservation: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema("reservations")
      .id()
      .field("start_date", .date, .required)
      .field("reservation_id", .string, .required)
      .field("ical_description", .string, .required)
      .field("uid", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("reservations").delete()
  }
}

