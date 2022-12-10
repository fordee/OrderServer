//
//  ProductsMongoController.swift
//  
//
//  Created by John Forde on 31/07/22.
//

import Foundation
import Vapor
import MongoDBVapor
import Models

struct ProductsMongoController : RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let productsRoute = routes.grouped("api", "mongo", "products")
    productsRoute.post(use: createHandler)
    productsRoute.get(use: getAllHandler)
    productsRoute.get(":_id", use: getHandler)
    productsRoute.post("upload", ":_id", use: productImageHandler)
    productsRoute.patch(":_id", use: updateHandler)
    productsRoute.delete(":_id", use: deleteHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [MongoProduct] {
//    guard let token = AuthController.token, let headerToken = req.headers["Authorization"].first, "BEARER \(token)" == "\(headerToken)" else {
//      throw Abort(.unauthorized)
//    }
    let headerToken = req.headers["Authorization"].first
    if !AuthController.authorize(token: headerToken) {
      throw Abort(.unauthorized)
    }

    return try await req.findProducts()
  }

  func getHandler(_ req: Request) async throws -> MongoProduct {
    try await req.findProduct()
  }


  func createHandler(_ req: Request) async throws -> MongoProduct {
    try await req.addProduct()
  }

  func updateHandler(_ req: Request) async throws -> Response {
    try await req.updateProduct()
  }

  func productImageHandler(_ req: Request) async throws -> String {
    let objectIdFilter = try req.getParameterId(parameterName: "_id")
    var product = try await req.findProduct()

    struct Input: Content {
      var file: File
    }

    struct MediaUpload: Codable {
      let fileExtension: String
      let image: Data
    }

    //let mediaUpload = try req.content.decode(MediaUpload.self)
    let mediaUpload = try JSONDecoder().decode(MediaUpload.self, from: req.body.data!)

    print("ContentType: \(mediaUpload.fileExtension)")
    guard let id = product.id else { return "" }//req.redirect(to: "/") } // If no id, can't upload image yet.

    let imageName = "/images/" + String("\(id).\(mediaUpload.fileExtension)")

    product.imagePath = imageName

    print("ImagePath: \(imageName)")
    let path = req.application.directory.publicDirectory + imageName

    let buffer = ByteBuffer(data: mediaUpload.image)
    try await req.fileio.writeFile(buffer, at: path)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(product))]
    _ = try await req.mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: req.productCollection)
    return path
    //return req.redirect(to: "/")
  }

  func deleteHandler(_ req: Request) async throws -> Response{
    try await req.deleteProduct()
  }

}

extension Request {
  var productCollection: MongoCollection<MongoProduct> {
    application.mongoDB.client.db("orderserver").collection("products", withType: MongoProduct.self)
  }

  func findProducts() async throws -> [MongoProduct] {
    return try await productCollection.find().toArray()
  }

  func findProduct() async throws -> MongoProduct {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    guard let product =  try await productCollection.findOne(objectIdFilter) else {
      throw Abort(.notFound)
    }
    return product
  }

  func addProduct() async throws -> MongoProduct {
    let product = try content.decode(MongoProduct.self)
    return try await mongoInsert(product, into: productCollection)
  }

  func updateProduct() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    let update = try content.decode(MongoProduct.self)
    print("update.name: \(update.name)")
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: productCollection)
  }

  func deleteProduct() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    return try await mongoDelete(filter: objectIdFilter, collection: productCollection)
  }
}
