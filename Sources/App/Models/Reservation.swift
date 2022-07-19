//
//  File.swift
//  
//
//  Created by John Forde on 19/07/22.
//

import Vapor
import Fluent

final class Reservation: Model {
  static let schema = "reservations"

  @ID
  var id: UUID?

  @Field(key: "start_date")
  var startDate: Date

  @Field(key: "end_date")
  var endDate: Date

  @Field(key: "reservation_id")
  var reservationId: String

  @Field(key: "ical_description")
  var iCalDescription: String

  @Field(key: "uid")
  var uid: String

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  // When this Planet was last updated.
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(id: UUID? = nil, startDate: Date, endDate: Date, reservationId: String, iCalDescription: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
    self.id = id
    self.startDate = startDate
    self.endDate = endDate
    self.reservationId = reservationId
    self.iCalDescription = iCalDescription
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

extension Reservation: Content {}
