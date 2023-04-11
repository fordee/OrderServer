
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import MongoDBVapor
import APNS

//import JWT


// configures your application
public func configure(_ app: Application) throws {
  app.routes.defaultMaxBodySize = "20mb"

  // uncomment to serve files from /Public folder
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
  print("app.directory.publicDirectory: \(app.directory.publicDirectory)")

  let corsConfiguration = CORSMiddleware.Configuration(
      allowedOrigin: .all,
      allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
      allowedHeaders: [.accessControlAllowHeaders, .accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, .authenticationControl, .accessControlAllowCredentials]
  )
  let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
  app.middleware.use(corsMiddleware)

  // Add HMAC with SHA-256 signer.
  //app.jwt.signers.use(.hs256(key: "fred"))

  app.logger.logLevel = .debug

  try app.autoMigrate().wait()
  
  app.views.use(.leaf)
  app.leaf.tags["now"] = NowTag()
  //app.http.client.configuration.redirectConfiguration = .disallow

  ContentConfiguration.global.use(encoder: ExtendedJSONEncoder(), for: .json)
  ContentConfiguration.global.use(decoder: ExtendedJSONDecoder(), for: .json)
  
  // register routes
  try routes(app)

  let apnsEnvironment: APNSwiftConfiguration.Environment
  apnsEnvironment = app.environment == .production ? .production : .sandbox
  let auth: APNSwiftConfiguration.AuthenticationMethod = try .jwt(
    key: .private(filePath: "/opt/orderserver/AuthKey_BFFL65Z935.p8"),
    keyIdentifier: "BFFL65Z935",
    teamIdentifier: "322WP4362D"
  )
  app.apns.configuration = .init(authenticationMethod: auth, topic: "net.4DWare.ShopAdmin", environment: apnsEnvironment)

}
