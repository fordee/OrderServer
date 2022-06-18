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

struct WebsiteController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: indexHandler)
  }

  func indexHandler(_ req: Request) async throws -> View {
    let products = try await Product.query(on: req.db).all()
    let context = IndexContext(title: "Home Page", products: products)
    return try await req.view.render("index", context)
  }
}
