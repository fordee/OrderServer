import Fluent
import Vapor

func routes(_ app: Application) throws {
//  let productsController = ProductsController()
//  try app.register(collection: productsController)

  let websiteController = WebsiteController()
  try app.register(collection: websiteController)

//  let stockPurchasesHandler = StockPurchasesController()
//  try app.register(collection: stockPurchasesHandler)

//  let customersController = CustomersController()
//  try app.register(collection: customersController)

//  let customerPurchasesConroller = CustomerOrderItemsController()
//  try app.register(collection: customerPurchasesConroller)

//  let reservationController = ReservationController()
//  try app.register(collection: reservationController)

//  let customerOrderController = CustomerOrdersController()
//  try app.register(collection: customerOrderController)

  let mongoOrderController = CustomerOrdersMongoController()
  try app.register(collection: mongoOrderController)

  let productsMongoController = ProductsMongoController()
  try app.register(collection: productsMongoController)

  let stockPurchasesHandler = StockPurchasesMongoController()
  try app.register(collection: stockPurchasesHandler)

  let reservationsMongoController = ReservationsMongoController()
  try app.register(collection: reservationsMongoController)

  let authController = AuthController()
  try app.register(collection: authController)

  let tokenController = TokenController()
  try app.register(collection: tokenController)
}
