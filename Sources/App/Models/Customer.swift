//
//  File.swift
//  
//
//  Created by John Forde on 8/07/22.
//

import Vapor
import Fluent

final class Customer: Model {
  static let schema = "customers"

  @ID
  var id: UUID?

  @Field(key: "username")
  var username: String

  @Field(key: "first_name")
  var first_name: String

  @Field(key: "last_name")
  var last_name: String

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  // When this Planet was last updated.
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(id: UUID? = nil, username: String, first_name: String, last_name: String) {
    self.id = id
    self.username = username
    self.first_name = first_name
    self.last_name = last_name
  }

}

extension Customer: Content {}
