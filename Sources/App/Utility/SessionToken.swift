//
//  SessionToken.swift
//  
//
//  Created by John Forde on 30/10/22.
//

//import Foundation
//import Vapor
//import JWT
//
//
//
//struct SessionToken: DecodableFromString, Content, Authenticatable, JWTPayload {
//
//  enum CodingKeys: String, CodingKey {
//    case subject = "sub"
//    case expiration = "exp"
//    case isAdmin = "admin"
//  }
//
//  // Constants
//  let expirationTime: TimeInterval = 60 * 15
//
//  // Token Data
//  var expiration: ExpirationClaim
// // var reservationId: String
//
//  init(reservationId: String) {
// //   self.reservationId: String
//    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
//  }
//
//  init(reservationId: String) throws {
// //   self.reservationId: String = try reservationId.requireID()
//    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
//  }
//
//  init(from: ) {
//
//  }
//
//  func verify(using signer: JWTSigner) throws {
//    try expiration.verifyNotExpired()
//  }
//}
