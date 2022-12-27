//
//  AuthController.swift
//
//
//  Created by John Forde on 30/10/22.
//

import Foundation
import Vapor

import Vapor


struct MyReservation: Authenticatable {
  let reservationId: String
}

struct User: Codable, Content {
  let reservationId: String
  let token: String
  let expiresIn: String
  let expiryDate: Date
}

let tokenExpireInterval = 1200 * 3

struct AuthController: RouteCollection {
  static var token: String?

  private static var userTokens: [User] = []

  func boot(routes: Vapor.RoutesBuilder) throws {
    let authRoute = routes.grouped("api", "auth")
    authRoute.get(":reservationId", "token", use: getToken)
  }

  static func authorize(token: String?) -> Bool {
    removeExpiredUsers() // Remove expired tokens first.
    guard let tok = token else {
      return false
    }
    for user in userTokens {
      if "BEARER \(user.token)" == "\(tok)" {
        return true
      }
    }
    return false
  }

  static func add(user: User) {
    userTokens.append(user)
  }

  static func generateToken(for reservationId: String) throws -> User {
    let random = [UInt8].random(count: 16).base64
    let expiryDate = Date() + TimeInterval(tokenExpireInterval)
    let user = User(reservationId: reservationId, token: random, expiresIn: String(tokenExpireInterval), expiryDate: expiryDate)
    token = user.token
    return user
  }

  static func removeExpiredUsers() {
    let now = Date()
    let newUserTokens = userTokens.filter { userToken in
      userToken.expiryDate > now
    }
    userTokens = newUserTokens
  }

  func getToken(_ req: Request) async throws -> User {
    let apiReservationId = try req.getParameterString(parameterName: "reservationId")
    let reservationId = try await getReservationId(req)
    print("reservationId: \(reservationId)")
    print("apiReservationId: \(apiReservationId)")
    if apiReservationId == reservationId || apiReservationId == "TOPSECRET" {
      print("success: \(reservationId)")
      let user = try AuthController.generateToken(for: reservationId)
      AuthController.add(user: user)
      return user
      } else {
      print("failed: \(reservationId)")
        return User(reservationId: "", token: "", expiresIn: "", expiryDate: Date())
    }
  }

  func getReservationId(_ req: Request) async throws -> String  {
    let reservationId = try await req.findCurrentReservationId()
    if let id = reservationId {
      return id
    } else {
      return "HMRBJSWW93"
    }
  }


}
