//
//  ReservationsMongoController.swift
//  
//
//  Created by John Forde on 25/08/22.
//

import Foundation
import Vapor
import MongoDBVapor
import Models

struct ReservationsMongoController: RouteCollection {
  func boot(routes: Vapor.RoutesBuilder) throws {
    let reservationsRoute = routes.grouped("api", "mongo", "reservations")
    reservationsRoute.post(use: createHandler)
    reservationsRoute.get(use: getAllHandler)
  }

  func createHandler(_ req: Request) async throws -> Reservation {
    try await req.addReservation()
  }

  func getAllHandler(_ req: Request) async throws -> [Reservation] {
    
    try await req.findReservations()
  }
}

extension Request {
  var reservationCollection: MongoCollection<Reservation> {
    application.mongoDB.client.db("orderserver").collection("reservations", withType: Reservation.self)
  }

  func findReservations() async throws -> [Reservation] {
    try await reservationCollection.find().toArray()
  }

  func findCurrentReservationId() async throws -> String? {
    let now = Calendar.current.dateComponents(in: .current, from: Date())

    // Create the start of the day in `DateComponents` by leaving off the time.
    let timeZone = TimeZone(abbreviation: "UTC")!
    print("timeZone: \(timeZone)")
    let today = DateComponents(timeZone: timeZone, year: now.year, month: now.month, day: now.day)
    let dateToday = Calendar.current.date(from: today)!
    print(dateToday)

    // Add 1 to the day to get tomorrow.
    let tomorrow = DateComponents(timeZone: timeZone, year: now.year, month: now.month, day: now.day! + 1)
    let dateTomorrow = Calendar.current.date(from: tomorrow)!
    print(dateTomorrow)

    let dateFilter: BSONDocument = ["startDate": ["$lte": .datetime(dateToday)], "endDate": ["$gt": .datetime(dateToday)]]
    let reservation = try await reservationCollection.findOne(dateFilter)
    print(reservation?.reservationId ?? "")
    return reservation?.reservationId
  }

  func addReservation() async throws -> Reservation {
    let reservation = try content.decode(Reservation.self)
    let updateDocument: BSONDocument = ["$set": .document(try BSONEncoder().encode(reservation))]
    let filter: BSONDocument = ["reservationId": .string(reservation.reservationId)]
    let result = try await mongoUpsert(filter: filter, updateDocument: updateDocument, collection: reservationCollection)//(reservation, into: reservationCollection)
    //let result = try await mongoInsert(reservation, into: reservationCollection)
    print(result)
    return reservation
  }
}
