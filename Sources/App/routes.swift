import Fluent
import Vapor

func routes(_ app: Application) throws {
  app.get { req in
    return req.view.render("index", ["title": "Hello Vapor!"])
  }
  
  app.get("hello") { req -> String in
    return "Hello, world!"
  }

  let productsController = ProductsController()
  try app.register(collection: productsController)

//  app.post("api", "products") { req -> EventLoopFuture<Product> in
//    let product = try req.content.decode(Product.self)
//    return product.save(on: req.db).map {
//      product
//    }
//  }
//
//  app.get("api", "products", ":productID") { req -> EventLoopFuture<Product> in
//    Product.find(req.parameters.get("productID"), on: req.db)
//      .unwrap(or: Abort(.notFound))
//  }
  
}
