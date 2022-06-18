import Fluent
import Vapor

func routes(_ app: Application) throws {
  let productsController = ProductsController()
  try app.register(collection: productsController)

  let websiteController = WebsiteController()
  try app.register(collection: websiteController)
  
}
