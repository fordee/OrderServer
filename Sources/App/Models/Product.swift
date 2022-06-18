//
//  Product.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Vapor
import Fluent

final class Product: Model {
  static let schema = "products"

  @ID
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Field(key: "description")
  var description: String

  @Field(key: "image_path")
  var imagePath: String

  init() {}

  init(id: UUID? = nil, name: String, description: String, imagePath: String) {
    self.id = id
    self.name = name
    self.description = description
    self.imagePath = imagePath
  }
}

extension Product: Content {}
