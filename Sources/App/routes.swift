import Fluent
import Vapor

func routes(_ app: Application) throws {
  app.get { req in
    return req.view.render("index", ["title": "Hello Vapor!"])
  }
  
  app.get("hello") { req -> String in
    return "Hello, world!"
  }

  app.post("api", "products") { req -> EventLoopFuture<Product> in
    let product = try req.content.decode(Product.self)
    return product.save(on: req.db).map {
      product
    }
  }
  
}
