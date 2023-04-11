//
//  File.swift
//  
//
//  Created by John Forde on 11/04/23.
//

import Foundation
import Vapor
import MongoDBVapor
import Models
import APNS

struct Token: Codable {
  let token: String
}

struct TokenController : RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let tokenRoute = routes.grouped("api", "token")
    tokenRoute.post(use: createHandler)
    tokenRoute.post("notify", use: notify)
    tokenRoute.delete(":token", use: deleteHandler)
  }

  func createHandler(_ req: Request) async throws -> Token {
    return try await req.addToken()
  }

  func deleteHandler(_ req: Request) async throws -> Response {
    return try await req.deleteToken()
  }

  func notify(_ req: Request) async throws -> HTTPStatus {
    let tokens = try await req.findTokens()
    guard !tokens.isEmpty else { return .noContent }

    let alert = APNSwiftAlert(title: "Hello!", body: "How are you today?")

    for token in tokens {
      print("token: \(token.token)")
      _ = req.apns.send(alert, to: token.token)

    }
//    return try await withCheckedThrowingContinuation
//    { continuation in
//      do {
//        try tokens.map { token in
//          req.apns.send(alert, to: token.token)
//          // 3
//
//        }
//        // 7
//        .flatten(on: req.eventLoop)
//        .wait()
//      } catch {
//        // 8
//        continuation.resume(throwing: error)
//      }
//      // 9
//      continuation.resume(returning: .noContent)
//    }
    return .ok
  }

}

extension Request {

  var tokenCollection: MongoCollection<Token> {
    application.mongoDB.client.db("orderserver").collection("tokens", withType: Token.self)
  }

  func findTokens() async throws -> [Token] {
    return try await tokenCollection.find().toArray()
  }

  func addToken() async throws -> Token {
    let token = try content.decode(Token.self)

    let tokens = try await findTokens()

    if tokens.contains(where: { $0.token == token.token }) {
      throw Abort(.conflict, reason: "\(token) already exists!")
    }

    do {
      let result = try await tokenCollection.insertOne(token) // Use the result to update the objectId
      print(result ?? "")
      return token
    } catch {
      // Give a more helpful error message in case of a duplicate key error.
      if let err = error as? MongoError.WriteError, err.writeFailure?.code == 11000 {
        throw Abort(.conflict, reason: "\(token) already exists!")
      }
      throw Abort(.internalServerError, reason: "Failed to save new order: \(error)")
    }

  }

  func deleteToken() async throws -> Response {
    guard let tokenString = self.parameters.get("token") else {
      throw Abort(.internalServerError, reason: "Request unexpectedly missing token parameter")
    }
    let objectIdFilter: BSONDocument = ["token": .string(tokenString)]
    return try await mongoDelete(filter: objectIdFilter, collection: tokenCollection)
  }

}
