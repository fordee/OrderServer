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
  let products: [MongoProduct]?
}

struct ProductContext: Encodable {
  let reservervationId: String
  let title: String
  let product: MongoProduct
  var message: String?

  init(reservervationId: String, title: String, product: MongoProduct, message: String? = nil) {
    self.reservervationId = reservervationId
    self.title = title
    self.product = product
    self.message = message
  }
}

struct MongoCartContext: Encodable {
  let title: String
  let order: MongoOrder?
  let reservationId: String
  var message: String?

  init(title: String, order: MongoOrder?, reservationId: String, message: String? = nil) {
    self.title = title
    self.order = order
    self.reservationId = reservationId
    self.message = message
  }
}

struct OrderConfirmationContext: Encodable {
  let title: String
  let order: MongoOrder?
  let reservationId: String
}

struct OrderSubmittedContext: Encodable {
  let title: String
  let order: MongoOrder?

}

struct LoginContext: Encodable {
  let title: String
  let message: String?
}

struct LoginPost: Content {
  let reservationId: String
}

var reservationLoginId: String? = nil // TODO: Handle this global state better.

struct WebsiteController: RouteCollection {
  let calendar = Calendar.current


  func boot(routes: RoutesBuilder) throws {
//    routes.get(use: indexHandler)
//    routes.get("products", ":_id", use: productHandler)
//    routes.post(":_id", "addtocart", use: addToCartMongoHandler)//addToCartHandler)
//    routes.get("cart", use: cartMongoHandler)//cartHandler)
//    //routes.get("login", use: loginController)
//    routes.post("login", use: loginPostController)
//    routes.post("order", use: orderController)
//    routes.get("confirmation", use: orderConfirmation)
//    routes.get(":_id", "submitted", use: orderSubmitted)
  }

  func loginController(_ req: Request) async throws -> View {
    let context = LoginContext(title: "Login", message: nil)
    return try await req.view.render("login", context)
  }

  func loginPostController(_ req: Request) async throws -> Response {
    let data = try req.content.decode(LoginPost.self)
    print(data)
    let reservationId = try await getReservationId(req)
    print(reservationId)
    if data.reservationId == reservationId {
      reservationLoginId = data.reservationId
    }
    return req.redirect(to: "/")
  }

  func orderController(_ req: Request) -> Response {
    return req.redirect(to: "/")
  }

  func addToCartMongoHandler(_ req: Request) async throws -> Response {
    let data = try req.content.decode(AddToCartData.self)

    // Perform validations
    do {
      try MongoOrder.validate(content: req)
    } catch let error as ValidationsError {
      let message = error.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
      return req.redirect(to: "/products/\(data.product?._id?.hex ?? "")?message=\(message)")
    }

    // Ensure we have Stock
    if let quantity = Int(data.quantity), let stock = Int(data.stock), quantity > stock {
      let message = "Not enough stock. Your order of \(data.quantity) exceeds stock of \(data.stock)."
      return req.redirect(to: "/products/\(data.product?._id?.hex ?? "")?message=\(message)")
    }

    let orders = try await req.findOpenOrders(by: try await getReservationId(req))
    print("orders: \(orders)")
    // Should only get one or none back. TODO: what if we get more than one?
    if orders.count == 1 { // user that order
      print("1 order")
      if let prod = data.product, let stock = Int(data.stock), let quant = Int(data.quantity), let sp = Double(data.sellingPrice) {
        let orderItem = MongoOrderItem(product: prod, quantity: quant, price: sp)
        _ = try await addOrderItem(orderItem, to: orders[0], request: req)
        // Reduce stock by quantity
        try await req.reduceProduct(productId: data._id, stock: stock , by: quant)
      }
    } else if orders.count == 0 { // Create new order
      // TODO: Create new order
      print("No orders.")
      guard let prod = data.product, let quant = Int(data.quantity), let sp = Double(data.sellingPrice) else {
        print("Can't get purchase data.")
        throw Abort(.notFound)
      }
      let orderItem = MongoOrderItem(product: prod, quantity: quant, price: sp)
      let newOrder = MongoOrder(reservationId: try await getReservationId(req), status: .open, paid: false, submittedTime: Date(), items: [orderItem])
      _ = try await req.mongoInsert(newOrder, into: req.orderCollection)
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
    let reservationId = try await getReservationId(req)
    if reservationLoginId == nil || reservationLoginId != reservationId {
      return try await loginController(req)
    }
    //let reservationId = try await getReservationId(req)
    let query: BSONDocument = ["reservationId": BSON(stringLiteral: reservationId), "status": "open"]
    let order = try await req.orderCollection.findOne(query)
    let context: MongoCartContext

    if let message = req.query[String.self, at: "message"] {
      context = MongoCartContext(title: "Shopping Cart", order: order, reservationId: reservationId, message: message)
      print("message: \(message)")
    } else {
      print("order: \(order)")
      context = MongoCartContext(title: "Shopping Cart", order: order, reservationId: reservationId)
    }

    return try await req.view.render("mongoCart.leaf", context)
  }

  func indexHandler(_ req: Request) async throws -> View {
    let reservationId = try await getReservationId(req)
    if reservationLoginId == nil || reservationLoginId != reservationId {
      return try await loginController(req)
    }
    let products = try await req.findProducts()
    let context = IndexContext(title: "Home Page", products: products)
    return try await req.view.render("index", context)
  }

  func productHandler(_ req: Request) async throws -> View {
    let reservationId = try await getReservationId(req)
    if reservationLoginId == nil || reservationLoginId != reservationId {
      return try await loginController(req)
    }
    let product = try await req.findProduct()
    let context: ProductContext
    if let message = req.query[String.self, at: "message"] {
      context = try await ProductContext(reservervationId: getReservationId(req), title: product.name, product: product, message: message)
    } else {
      context = try await ProductContext(reservervationId: getReservationId(req), title: product.name, product: product)
    }
    return try await req.view.render("product", context)
  }

  func getReservationId(_ req: Request) async throws -> String  {
    let reservationId = try await req.findCurrentReservationId()
    if let id = reservationId {
      return id
    } else {
      return "HMRBJSWW93"
    }
  }

  func orderConfirmation(_ req: Request) async throws -> View {
    let reservationId = try await getReservationId(req)
    if reservationLoginId == nil || reservationLoginId != reservationId {
      return try await loginController(req)
    }
    let query: BSONDocument = ["reservationId": BSON(stringLiteral: reservationId), "status": "open"]
    let order = try await req.orderCollection.findOne(query)
    let context = OrderConfirmationContext(title: "Confirm Order", order: order, reservationId: reservationId)

    return try await req.view.render("orderConfirmation.leaf", context)
  }

  func orderSubmitted(_ req: Request) async throws -> View {
    let reservationId = try await getReservationId(req)
    if reservationLoginId == nil || reservationLoginId != reservationId {
      return try await loginController(req)
    }
    let objectIdFilter = try req.getParameterId(parameterName: "_id")
    //let query: BSONDocument = ["_id": .objectID(id)]//["reservationId": BSON(stringLiteral: reservationId), "status": "submitted"]
    let order = try await req.orderCollection.findOne(objectIdFilter)
    let context = OrderConfirmationContext(title: "Order Submitted", order: order, reservationId: reservationId)

    return try await req.view.render("submitted.leaf", context)
  }
}

struct NowTag: LeafTag {

  func render(_ ctx: LeafContext) throws -> LeafData {
    let formatter = DateFormatter()
    switch ctx.parameters.count {
    case 0: formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    case 1:
      guard let string = ctx.parameters[0].string else {
        throw NowTagError()
      }
      formatter.dateFormat = string
    default:
      throw NowTagError()
    }

    let dateAsString = formatter.string(from: Date())
    return LeafData.string(dateAsString)
  }
}

struct NowTagError: Error {}

extension Request {
  func reduceProduct(productId: String, stock: Int, by quantity: Int) async throws {
    assert((stock - quantity) >= 0)
    let newStock = stock - quantity
    let objectIdFilter: BSONDocument = ["_id": .objectID(try BSONObjectID(productId))]
    let update: BSONDocument = ["stock": BSON(integerLiteral: newStock)]
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(update))]
    _ = try await mongoUpdate(filter: objectIdFilter, updateDocument: updateDocument, collection: productCollection)
  }
}

extension MongoOrder: Validatable {
  public static func validations(_ validations: inout Validations) {
    validations.add("quantity", as: Int.self, is: .range(0...99), required: true)
  }
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

