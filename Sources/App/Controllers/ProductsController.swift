//
//  ProductsController.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Vapor
import Fluent

struct ProductsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let productsRoutes = routes.grouped("api", "products")

    productsRoutes.get(use: getAllHandler)
    productsRoutes.post(use: createHandler)
    productsRoutes.get(":productID", use: getHandler)
    productsRoutes.put(":productID", use: updateHandler)
    productsRoutes.delete(":productID", use: deleteHandler)
    productsRoutes.get("search", use: searchHandler)
    productsRoutes.get("first", use: getFirstHandler)
    productsRoutes.get("sorted", use: sortedHandler)
    productsRoutes.post("upload", ":productID", use: productImageHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [Product] {
    try await Product.query(on: req.db).all()
  }

  func createHandler(_ req: Request) async throws -> Product {
    let product = try req.content.decode(Product.self)
    try await product.save(on: req.db)
    return product
  }

  func getHandler(_ req: Request) async throws -> Product {
    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
      throw Abort(.notFound)
    }
    return product
  }

  func updateHandler(_ req: Request) async throws -> Product {
    let updatedProduct = try req.content.decode(Product.self)
    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
      throw Abort(.notFound)
    }
    product.name = updatedProduct.name
    product.description = updatedProduct.description
    product.imagePath = updatedProduct.imagePath
    product.price = updatedProduct.price
    product.quantity = updatedProduct.quantity
    try await product.save(on: req.db)
    return product
  }

  func deleteHandler(_ req: Request) async throws -> HTTPStatus {
    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else { throw Abort(.noContent) }
    try await product.delete(on: req.db)
    return .ok
  }

  func searchHandler(_ req: Request) async throws -> [Product] {
    guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
    return try await Product.query(on: req.db).group(.or) { or in
      or.filter(\.$name == searchTerm)
      or.filter(\.$description == searchTerm)
    }.all()
  }

  func getFirstHandler(_ req: Request) async throws -> Product {
    guard let product = try await Product.query(on: req.db).first() else {
      throw Abort(.notFound)
    }
    return product
  }

  func sortedHandler(_ req: Request) async throws -> [Product] {
    return try await Product.query(on: req.db)
      .sort(\.$name, .ascending).all()
  }

  func uploadImage(_ req: Request) async throws -> HTTPStatus {
    let uuid = req.parameters.get("id", as: UUID.self)
    let file = try req.content.decode(File.self)
    var fileName = "\(uuid?.uuidString ?? "").\(Date().timeIntervalSince1970)"
    fileName = file.extension.flatMap { "\(fileName).\($0)" } ?? fileName
    let path = req.application.directory.workingDirectory + fileName

    //    guard file.isImage else {
    //      throw Abort(.badRequest)
    //    }

    try await req.fileio.writeFile(file.data, at: path)
    return .ok
  }

  func upload(_ req: Request) async throws -> HTTPStatus {
    struct Input: Content {
      var file: File
    }
    let input = try req.content.decode(File.self)

    let path = req.application.directory.publicDirectory + input.filename

    let fileData = try await req.fileio.collectFile(at: path)
    try await req.fileio.writeFile(fileData, at: path)
    return .ok
//    .flatMap { handle in
//      req.application.fileio.write(fileHandle: handle,
//                                   buffer: input.file.data,
//                                   eventLoop: req.eventLoop)
//      .flatMapThrowing { _ in
//        try handle.close()
//        return input.file.filename
//      }
//    }
  }
  func productImageHandler(_ req: Request) async throws -> Response {
    struct UserFile: Content {
      var data: Data
    }

    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else { throw Abort(.noContent) }

    struct Input: Content {
      var file: File
    }
    let data = try req.content.decode(Input.self)

    //let data = try req.content.decode(ImageUploadData.self)

    print("ContentType: \(data.file.filename)")
    guard let id = product.id else { return req.redirect(to: "/") } // If no id, can't upload image yet.

    let imageName = "/images/" + String("\(id).\(data.file.extension ?? "jpg")")

    product.imagePath = imageName

    print("ImagePath: \(imageName)")
    let path = req.application.directory.publicDirectory + imageName

    try await req.fileio.writeFile(data.file.data, at: path)
    try await product.save(on: req.db)
    return req.redirect(to: "/")
  }

}
