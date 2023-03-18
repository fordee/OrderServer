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

enum SortDirection: String, RawRepresentable {
  case asc = "asc"
  case desc = "desc"
}

struct ProductsMongoController : RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let productsRoute = routes.grouped("api", "mongo", "products")
    productsRoute.post(use: createHandler)
    productsRoute.get(use: getAllHandler)
    productsRoute.get("paged", ":sort", ":pageSize", ":pageIndex", use: getAllPagedHandler)
    productsRoute.get("productCount", use: getProductCount)
    productsRoute.get(":_id", use: getHandler)
    productsRoute.post("upload", ":_id", use: productImageHandler)
    productsRoute.patch(":_id", use: updateHandler)
    productsRoute.delete(":_id", use: deleteHandler)
//    productsRoute.patch(":_id", "updateStockAmount", use: updateStockAmount)
  }

  func getProductCount(_ req: Request) async throws -> Int {
    try await req.productCount()
  }

//  func updateStockAmount(_ req: Request) async throws -> MongoProduct {
//    try await req.updateStockAmount()
//  }

  func getAllHandler(_ req: Request) async throws -> [MongoProduct] {
    let headerToken = req.headers["Authorization"].first
    if !AuthController.authorize(token: headerToken) {
      throw Abort(.unauthorized)
    }
    return try await req.findProducts()
  }

  func getAllPagedHandler(_ req: Request) async throws -> [MongoProduct] {
    let headerToken = req.headers["Authorization"].first
    if !AuthController.authorize(token: headerToken) {
      throw Abort(.unauthorized)
    }
    let sortDirection = SortDirection(rawValue: try req.getParameterString(parameterName: "sort"))
    var pageSize = Int(try req.getParameterString(parameterName: "pageSize")) ?? 24 // If we can't get page size, use 24
    var pageIndex = Int(try req.getParameterString(parameterName: "pageIndex")) ?? 0 // If we can't get page number, use 0
    let category: String? = req.query["category"]//req.getParameterString(parameterName: "category")

    let filteredArray: [MongoProduct]
    if let category {
      print("category: \(category)")
      filteredArray = try await req.findProducts().filter { product in
        product.categories.contains(category)
      }
    } else {
      print("category is nil")
      filteredArray = try await req.findProducts()
    }

    let sortedArray = filteredArray.sorted { lhs, rhs in
      switch sortDirection {
      case .asc:
        return lhs.name < rhs.name
      case .desc:
        return lhs.name > rhs.name
      case .none:
        print("Error: invalid sort direction.")
        return lhs.name < rhs.name // Just assume asc
      }
    }
    let maxpageIndex = sortedArray.count / pageSize
    pageIndex = min(pageIndex, maxpageIndex)
    let maxPageSize: Int
    if pageIndex == maxpageIndex {
      maxPageSize = sortedArray.count - (pageSize * pageIndex)
    } else {
      maxPageSize = pageSize
    }
    let startIndex = pageSize * pageIndex
    print("pageIndex: \(pageIndex), maxpageIndex: \(maxpageIndex)")
    pageSize = min(pageSize, maxPageSize)



    print("startIndex: \(startIndex)")

    return Array(sortedArray[startIndex..<startIndex + maxPageSize])
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
    //guard let id = product.id else { return "" }//req.redirect(to: "/") } // If no id, can't upload image yet.
    let id = String.randomString(length: 16)
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

  func productCount() async throws -> Int {
    return try await productCollection.find().toArray().count
  }

//  func updateStockAmount() async throws -> MongoProduct {
//    let objectIdFilter = try getParameterId(parameterName: "_id")
//    let update = try content.decode(MongoProduct.self)
//    //return MongoProduct(name: "", description: "", imagePath: "", stock: 0, sellingPrice: 0.0)
//  }

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
    print("update.stock: \(update.stock)")
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
    print(updateDocument.values)  // ["bestByDate": nil]
    return try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: productCollection)
  }

  func deleteProduct() async throws -> Response {
    let objectIdFilter = try getParameterId(parameterName: "_id")
    return try await mongoDelete(filter: objectIdFilter, collection: productCollection)
  }
}
