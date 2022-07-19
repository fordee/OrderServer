//
//  File.swift
//  
//
//  Created by John Forde on 19/07/22.
//

import Vapor
import Fluent

struct AdminController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let adminRoute = routes.grouped("api", "admin")
    adminRoute.get(use: getAllHandler)
    adminRoute.post("upload", use: uploadHandler)
  }

  func getAllHandler(_ req: Request) async throws -> [Reservation] {
    try await Reservation.query(on: req.db).all()
  }

  func uploadHandler(_ req: Request) async throws -> Response {
    struct Input: Content {
      var file: File
    }
    let data = try req.content.decode(Input.self)
    let calendarFilename = "/iCalfile.ics"
    let path = req.application.directory.publicDirectory + calendarFilename

    try await req.fileio.writeFile(data.file.data, at: path)
    // TODO: Parse clandar file and save all reservations.
    // TODO: Work out how to do a diff of existing reservations.
    // 1. Get all reservations from database.
    // 2. Parse iCal file
    // 3. Loop and match on reservationId, checkInDate and checkOutDate. If match, skip to the next one.
    // If no match, save reservation.
    // Need to decide if we delete remaining ones not in iCal file past today.

    let buffer = try await req.fileio.collectFile(at: path)
    let fileContents = String(buffer: buffer)

    let reservations = parseFile(fileContents: fileContents)
    print(reservations)

    return req.redirect(to: "/")

  }

  func parseFile(fileContents: String) -> [Reservation] {
    var reservations: [Reservation] = []
    let pattern = "Reservation URL: https://www.airbnb.com/hosting/reservations/details/(?<id>[A-Z0-9]*)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return reservations } // Fail if it can't be created

    var calendarParser = CalendarParser(fileContents)
    calendarParser.parseIcalFile()
    print(calendarParser.events)

    for event in calendarParser.events {
      if let endDate = event.dtend?.date, let description = event.description {
        let reservationId = ""
//        let regex = /Reservation URL: https:\/\/www.airbnb.com\/hosting\/reservations\/details\/(?<id>[A-Z0-9]*)/
//        do {
//          if let result = try regex.prefixMatch(in: description) {
//            print(result.id)
//            reservationId = String(result.id)
//          }
//        } catch {
//          print(error)
//        }
        let reservation = Reservation(startDate: event.dtstart.date!, endDate: endDate, reservationId: reservationId, iCalDescription: description, uid: event.uid)
        reservations.append(reservation)
        print("Event Summary: \(event.summary)")
      }
    }

    return reservations
  }

}

struct ICalUpload: Codable {
  let fileExtension: String
  let image: Data
}
