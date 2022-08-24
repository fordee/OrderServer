//
//  Product.swift
//  
//
//  Created by John Forde on 19/06/22.
//

//import Vapor
//import Fluent
//
//final class Product: Model {
//  static let schema = "products"
//
//  @ID
//  var id: UUID?
//
//  @Field(key: "name")
//  var name: String
//
//  @Field(key: "description")
//  var description: String
//
//  @Field(key: "image_path")
//  var imagePath: String
//
//  @Field(key: "price")
//  var price: Double
//
//  @Field(key: "quantity")
//  var quantity: Int
//
//  @Field(key: "average_purchase_price")
//  var averagePurchasePrice: Double
//
//  @Timestamp(key: "created_at", on: .create)
//  var createdAt: Date?
//
//  // When this Planet was last updated.
//  @Timestamp(key: "updated_at", on: .update)
//  var updatedAt: Date?
//
//  init() {}
//
//  init(id: UUID? = nil, name: String, description: String, imagePath: String) {
//    self.id = id
//    self.name = name
//    self.description = description
//    self.imagePath = imagePath
//  }
//  
//}
//
//extension Product: Content {}
