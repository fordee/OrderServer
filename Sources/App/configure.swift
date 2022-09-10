
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import MongoDBVapor



// configures your application
public func configure(_ app: Application) throws {
  app.routes.defaultMaxBodySize = "20mb"

  // uncomment to serve files from /Public folder
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
  
//  app.databases.use(.postgres(
//    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
//    port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
//    username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
//    password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
//    database: Environment.get("DATABASE_NAME") ?? "vapor_database"
//  ), as: .psql)
//
//  app.migrations.add(CreateProduct())
//  app.migrations.add(CreateStockPurchase())
//  //app.migrations.add(CreateCustomer())
//
//  app.migrations.add(CreateReservation())
//  app.migrations.add(CreateCustomerOrder())
//  app.migrations.add(CreateCustomerOrderItem())

  app.logger.logLevel = .debug

  try app.autoMigrate().wait()
  
  app.views.use(.leaf)
  app.leaf.tags["now"] = NowTag()

  ContentConfiguration.global.use(encoder: ExtendedJSONEncoder(), for: .json)
  ContentConfiguration.global.use(decoder: ExtendedJSONDecoder(), for: .json)
  
  // register routes
  try routes(app)
}
