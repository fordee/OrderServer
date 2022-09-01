//
//  WebsiteController.swift
//  
//
//  Created by John Forde on 19/06/22.
//

import Vapor
import Leaf
import Fluent
import Models

import MongoDBVapor

struct IndexContext: Encodable {
  let title: String
  let products: [MongoProduct]?//[Product]?
}

struct ProductContext: Encodable {
  let title: String
  let product: MongoProduct//Product
}


struct ProductUploadContext: Encodable {
  let title: String
  let product: MongoProduct
}

struct UploadContext: Encodable {
  let title: String
  let username: String
}

struct AdminContext: Encodable {
  let title: String
  let reservations: [MongoReservation]?
}

//struct CartContext: Encodable {
//  let title: String
//  let orderItems: [CustomerOrderItem]?
//}

struct MongoCartContext: Encodable {
  let title: String
  let order: MongoOrder?
}

struct WebsiteController: RouteCollection {
  let calendar = Calendar.current
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: indexHandler)
    routes.get("products", ":_id", use: productHandler)
    routes.get("upload", ":_id", use: uploadHandler)
    //routes.get("reservations", use: reservationHandler)
    routes.post(":_id", "addtocart", use: addToCartMongoHandler)//addToCartHandler)
    routes.get("cart", use: cartMongoHandler)//cartHandler)
  }

  //  func addToCartHandler(_ req: Request) async throws -> Response {
  //    let data = try req.content.decode(AddToCartData.self)
  //    print("quantity: \(data.quantity)")
  //    print("product: \(data.product)")
  //    print("price: \(data.price)")
  //    // Check to see if order exists
  //    // If not create a new one and assign the reservation
  //    // If orders exist with status completed, then create a new one
  //    // If not use existing order
  //
  //    let reservationId = "HM4AC8TMNS"
  //    let orders = try await CustomerOrder.query(on: req.db)
  //      .all()
  //
  //    for order in orders {
  //      let orderReservationId = try await order.$reservation.get(on: req.db).reservationId
  //      if reservationId == orderReservationId {
  //        print("OrderId: \(order.id!)") // TODO: Use API createHandler?
  //        let id = try order.requireID()
  //        guard let quantity = Int(data.quantity) else { throw Abort(.notFound) } // TODO: proper error handling
  //        guard let price = Double(data.price) else { throw Abort(.notFound) }
  //        let item = CustomerOrderItem(productId: data.product, price: price, quantity: quantity, customerOrderID: id)
  //        try await item.save(on: req.db)
  //      }
  //    }
  //
  //    return req.redirect(to: "/")
  //  }

  func addToCartMongoHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(AddToCartData.self)
    print("product: \(String(describing: data.product))")

    let orders = try await req.findOpenOrders(by: "HMRBJSWW93")//req.findOrders()
    print("orders: \(orders)")
    // Should only get one or none back. TODO: what if we get more than one?
    if orders.count == 1 { // user that order
      print("1 order")
      if let prod = data.product, let quant = Int(data.quantity), let sp = Double(data.sellingPrice) {
        let fred = MongoOrderItem(product: prod, quantity: quant, price: sp)
        return try await addOrderItem(fred, to: orders[0], request: req)
      }
      //return try await addOrderItemFred(fred, to: orders[0])
    } else if orders.count == 0 { // Create new order
      // TODO: Create new order
      print("No orders.")
    } else { // Error
      print("Error: Too many open orders.")
    }

    return req.redirect(to: "/")
  }

  func addOrderItem(_ item: MongoOrderItem, to order: MongoOrder, request: Request) async throws -> Response {
    print("item: \(item)")
    print("order: \(order)")
    // First add to items
    guard let id = order._id else { throw Abort(.notFound) }

    // Get all items in order
    let query: BSONDocument = ["_id": .objectID(id)]
    let items = try await request.orderCollection.findOne(query)?.items ?? []
    print("Order ID: \(id.hex) Items: \(items)")

    var response: Response
    let objectIdFilter: BSONDocument = ["_id": .objectID(id)]

    var newItems: [MongoOrderItem] = []
    var itemWithSameProductExists = false
    for itemIter in items {
      if itemIter.product._id == item.product.id && itemIter.product.sellingPrice == item.product.sellingPrice {
        let upatedItem = MongoOrderItem(product: item.product, quantity: item.quantity + itemIter.quantity, price: item.price)
        newItems.append(upatedItem)
        itemWithSameProductExists = true
      } else {
        newItems.append(itemIter)
      }
    }
    if itemWithSameProductExists {
      let itemsUpdateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(["items": newItems]))]
      response = try await request.mongoUpdate(filter: objectIdFilter, updateDocument: itemsUpdateDocument, collection: request.orderCollection)
      return response
    } else {
      let updateDocument: BSONDocument = ["$push": .document(try BSONEncoder().encode(["items": item]))]
      response = try await request.mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: request.orderCollection)
      return response
    }

  }

  func cartMongoHandler(_ req: Request) async throws -> View {
    //let products = try await Product.query(on: req.db).all()
    let query: BSONDocument = ["reservationId": "HMRBJSWW93", "status": "open"]
    let order = try await req.orderCollection.findOne(query)
    //  print("order: \(order)")
    let context = MongoCartContext(title: "Shopping Cart", order: order)
    //  print("context: \(context)")
    return try await req.view.render("mongoCart.leaf", context)
  }

  func indexHandler(_ req: Request) async throws -> View {
    let reservationsData = ReservationsParser.parseFile()
    for row in reservationsData.rows {
      for (key, value) in row {
        print("key: \(key), value: \(value)")
      }
    }
    
    //let products = try await Product.query(on: req.db).all()
    let products = try await req.findProducts()
    let context = IndexContext(title: "Home Page", products: products)
    return try await req.view.render("index", context)
  }

  func productHandler(_ req: Request) async throws -> View {
    let product = try await req.findProduct()
    //    guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
    //      throw Abort(.notFound)
    //    }
    let context = ProductContext(title: product.name, product: product)
    return try await req.view.render("product", context)
  }

  func uploadHandler(_ req: Request) async throws -> View {
    let product = try await req.findProduct()
    let context = ProductUploadContext(title: "File Upload", product: product)
    return try await req.view.render("upload", context)
  }

  

//  func reservationHandler(_ req: Request) async throws -> View {
//    let reservations = try await Reservation.query(on: req.db).all()
//    let context =  AdminContext(title: "Reservation", reservations: reservations)
//    return try await req.view.render("reservation", context)
//  }
//
//  func getCurrentReservationIds(_ req: Request) async throws -> [String] {
//
//    var dateComponents = DateComponents()
//    dateComponents.year = 2022
//    dateComponents.month = 8
//    dateComponents.day = 7
//    dateComponents.timeZone = TimeZone.utc
//    dateComponents.hour = 8
//    dateComponents.minute = 34
//    let testDate = calendar.date(from: dateComponents)!
//    print("testDate: \(testDate)")
//
//    let reservations = try await Reservation.query(on: req.db).all()
//
//    var reservationIds: [String] = []
//
//    for reservation in reservations {
//      if (calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedSame ||
//          calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedAscending) &&
//          (calendar.compare(reservation.endDate, to: testDate, toGranularity: .day) == .orderedSame ||
//           calendar.compare(reservation.endDate, to: testDate, toGranularity: .day) == .orderedDescending) {
//        print("Start Date: \(reservation.startDate) *******************************************************")
//        //        print(calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedSame)
//        //        print(calendar.compare(reservation.startDate, to: testDate, toGranularity: .day) == .orderedAscending)
//        //        print(calendar.compare(reservation.endDate, to: testDate, toGranularity: .day) == .orderedDescending)
//        reservationIds.append(reservation.reservationId)
//      }
//    }
//    return reservationIds
//  }

}

struct ImageUploadData: Content {
  var picture: Data
}

struct AddToCartData: Content {
  var _id: String
  var name: String
  var description: String
  var imagePath: String
  var stock: String
  var quantity: String
  var sellingPrice: String
  var bestByDate: String

  var product: MongoProduct? {
    if let epoch = Double(bestByDate), let stockInt = Int(stock), let sp = Double(sellingPrice) {
      let bbDate = Date.init(timeIntervalSince1970: epoch)
      return MongoProduct(_id: try? BSONObjectID(_id), name: name, description: description, imagePath: imagePath, stock: stockInt, sellingPrice: sp, bestByDate: bbDate)
    } else {
      return nil
    }
  }
}

//extension Request {
//  func findProduct() async throws -> MongoProduct {
//    let objectIdFilter = try getParameterId(parameterName: "_id")
//    guard let product = try await productCollection.findOne(objectIdFilter) else {
//      throw Abort(.notFound, reason: "No order found")
//    }
//    return product
//  }
//}
