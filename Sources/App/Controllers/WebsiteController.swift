//
//  WebsiteController.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Vapor
import Leaf
import Fluent

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

struct CartContext: Encodable {
  let title: String
  let orderItems: [CustomerOrderItem]?
}

struct WebsiteController: RouteCollection {
  let calendar = Calendar.current
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: indexHandler)
    routes.get("products", ":productID", use: productHandler)
    routes.get("upload", ":productID", use: uploadHandler)
    routes.get("reservations", use: reservationHandler)
    routes.post(":productID", "addtocart", use: addToCartHandler)
    routes.get("cart", use: cartHandler)
  }

  func addToCartHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(AddToCartData.self)
    print("quantity: \(data.quantity)")
    print("product: \(data.product)")
    print("price: \(data.price)")
    // Check to see if order exists
    // If not create a new one and assign the reservation
    // If orders exist with status completed, then create a new one
    // If not use existing order

    let reservationId = "HM4AC8TMNS"
    let orders = try await CustomerOrder.query(on: req.db)
      .all()

    for order in orders {
      let orderReservationId = try await order.$reservation.get(on: req.db).reservationId
      if reservationId == orderReservationId {
        print("OrderId: \(order.id!)")
        let id = try order.requireID()
        guard let quantity = Int(data.quantity) else { throw Abort(.notFound) } // TODO: proper error handling
        guard let price = Double(data.price) else { throw Abort(.notFound) }
        let item = CustomerOrderItem(productId: data.product, price: price, quantity: quantity, customerOrderID: id)
        try await item.save(on: req.db)
      }
    }
//    let bookingCodes = try await getCurrentReservationIds(req)
//    for bc in bookingCodes {
//      print("Booking Code: \(bc)")
//    }
    return req.redirect(to: "/")
  }

  func cartHandler(_ req: Request) async throws -> View {
    let orderId = UUID("ABC3C85D-44C5-4C05-A453-55046D0882BF")!


    let orderItems = try await CustomerOrderItem.query(on: req.db)
      //.filter(.sql(raw: "customerOrderID = \(orderId)"))
      .all()

    let items = orderItems.filter( { $0.$customerOrder.id == orderId } )

    let context = CartContext(title: "Shopping Cart", orderItems: items)
    return try await req.view.render("cart", context)
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

  func reservationHandler(_ req: Request) async throws -> View {
    let reservations = try await Reservation.query(on: req.db).all()
    let context =  AdminContext(title: "Reservation", reservations: reservations)
    return try await req.view.render("reservation", context)
  }

  func getCurrentReservationIds(_ req: Request) async throws -> [String] {

    var dateComponents = DateComponents()
    dateComponents.year = 2022
    dateComponents.month = 8
    dateComponents.day = 7
    dateComponents.timeZone = TimeZone.utc
    dateComponents.hour = 8
    dateComponents.minute = 34
    let testDate = calendar.date(from: dateComponents)!
    print("testDate: \(testDate)")

    let reservations = try await Reservation.query(on: req.db).all()

    var reservationIds: [String] = []

    for reservation in reservations {
      if (calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedSame ||
          calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedAscending) &&
         (calendar.compare(reservation.endDate, to: testDate, toGranularity: .day) == .orderedSame ||
          calendar.compare(reservation.endDate, to: testDate, toGranularity: .day) == .orderedDescending) {
        print("Start Date: \(reservation.startDate) *******************************************************")
//        print(calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedSame)
//        print(calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedAscending)
//        print(calendar.compare(reservation.endDate, to: testDate, toGranularity: .day) == .orderedDescending)
        reservationIds.append(reservation.reservationId)
      }
    }
    return reservationIds
  }

}

struct ImageUploadData: Content {
  var picture: Data
}

struct AddToCartData: Content {
  var quantity: String
  var product: String
  var price: String
}
