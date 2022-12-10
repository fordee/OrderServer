// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "OrderServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
        .package(url: "https://github.com/tbartelmess/swift-ical.git", from: "0.0.8"),
        //.package(url: "https://github.com/mongodb/mongo-swift-driver", from: "1.3.1")
        .package(url: "https://github.com/mongodb/mongodb-vapor", from: "1.1.0-beta.1"),
        .package(url: "https://github.com/fordee/models", branch: "main"),
        .package(url: "https://github.com/swiftcsv/SwiftCSV.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SwiftIcal", package: "swift-ical"),
                .product(name: "MongoDBVapor", package: "mongodb-vapor"),
                .product(name: "Models", package: "models"),
                .product(name: "SwiftCSV", package: "SwiftCSV"),
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [
          .target(name: "App"),
          .product(name: "MongoDBVapor", package: "mongodb-vapor")
        ]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
