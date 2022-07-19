//
//  WebsiteController.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Vapor
import Leaf

struct IndexContext: Encodable {
  let title: String
  let products: [Product]?
}

struct ProductContext: Encodable {
  let title: String
  let product: Product
}

struct UploadContext: Encodable {
  let title: String
  let username: String
}

struct AdminContext: Encodable {
  let title: String
  let reservations: [Reservation]?
}

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: indexHandler)
    routes.get("products", ":productID", use: productHandler)
    routes.get("upload", ":productID", use: uploadHandler)
    routes.get("admin", use: adminHandler)
  }

  func indexHandler(_ req: Request) async throws -> View {
    let products = try await Product.query(on: req.db).all()
    let context = IndexContext(title: "Home Page", products: products)
    return try await req.view.render("index", context)
  }

  func productHandler(_ req: Request) async throws -> View {
    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let context = ProductContext(title: product.name, product: product)
    return try await req.view.render("product", context)
  }

  func uploadHandler(_ req: Request) async throws -> View {
    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
      throw Abort(.notFound)
    }
    let context = ProductContext(title: "File Upload", product: product)
    return try await req.view.render("upload", context)
  }

  func adminHandler(_ req: Request) async throws -> View {
    let reservations = try await Reservation.query(on: req.db).all()
    let context =  AdminContext(title: "Admin", reservations: reservations)
    return try await req.view.render("admin", context)
  }

}

struct ImageUploadData: Content {
  var picture: Data
}
