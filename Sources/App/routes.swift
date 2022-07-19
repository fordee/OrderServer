import Fluent
import Vapor

func routes(_ app: Application) throws {
  let productsController = ProductsController()
  try app.register(collection: productsController)

  let websiteController = WebsiteController()
  try app.register(collection: websiteController)

  let stockPurchasesHandler = StockPurchasesController()
  try app.register(collection: stockPurchasesHandler)

  let customersController = CustomersController()
  try app.register(collection: customersController)

  let customerPurchasesConroller = CustomerPurchasesController()
  try app.register(collection: customerPurchasesConroller)

  let adminController = AdminController()
  try app.register(collection: adminController)
  
}
