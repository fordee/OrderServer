//
//  ReservationsParser.swift
//  
//
//  Created by John Forde on 27/08/22.
//

import Foundation
import SwiftCSV

struct ReservationsParser {
  static func parseFile() -> CSV<Named> {
    let csvFile: CSV<Named>
    do {
      csvFile = try CSV<Named>(url: URL(fileURLWithPath: "/Users/fordee/Downloads/reservations.csv"))
      print("csvFile: \(csvFile.header)")
    } catch {
      fatalError(error.localizedDescription)
    }
    return csvFile

  }
}
