//
//  AdminController.swift
//  
//
//  Created by John Forde on 19/07/22.
//

import Vapor
import Fluent

struct AdminController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let adminRoute = routes.grouped("api", "admin")
    adminRoute.get("reservations", use: getAllHandler)
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
    // Need to decide if we delete remaining ones not in iCal file past today. Also, what about updates.
    let dbReservations = try await getAllHandler(req)

    let buffer = try await req.fileio.collectFile(at: path)
    let fileContents = String(buffer: buffer)

    let reservations = parseFile(fileContents: fileContents)
    for reservation in reservations {
      if dbReservations.map({ $0.uid }).contains(reservation.uid) {
        // Don't save TODO: Do we update?
        print("\(reservation.reservationId) already exists. Didn't save.")
      } else {
        try await reservation.save(on: req.db)
        print("Saving \(reservation.reservationId)")
      }
    }
    return req.redirect(to: "/")
  }

  func parseFile(fileContents: String) -> [Reservation] {
    var reservations: [Reservation] = []
    let reservationIdPattern = "Reservation URL: https://www.airbnb.com/hosting/reservations/details/(?<id>[A-Z0-9]*)"
    guard let regex = try? NSRegularExpression(pattern: reservationIdPattern) else { return reservations } // Fail if it can't be created

    var calendarParser = CalendarParser(fileContents)
    calendarParser.parseIcalFile()
    print(calendarParser.events)

    for event in calendarParser.events {
      if let endDate = event.dtend?.date, let description = event.description {
        var reservationId = ""
        let range = NSRange(description.startIndex..., in: description)
        let result = regex.firstMatch(in: description, range: range)
        print("result: \(String(describing: result?.numberOfRanges))")
        if result?.numberOfRanges == 2 {
          if let firstCaptureRange = result?.range(at: 1), let swiftRange = Range(firstCaptureRange, in: description) {
            //print("result: \(String(describing: description[swiftRange]))")
            reservationId = String(description[swiftRange])
          }
        }
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
        print("Event Summary: \(event.summary!)")
      }
    }

    return reservations
  }

}

struct ICalUpload: Codable {
  let fileExtension: String
  let image: Data
}
