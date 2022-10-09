//
//  File.swift
//  
//
//  Created by John Forde on 24/06/22.
//

import Foundation

extension String {
  func stringToDateComponents() -> DateComponents {
    let calendar = Calendar.current

    var temp = self
    let year = Int(temp.prefix(4))
    temp.removeFirst(4)
    let month = Int(temp.prefix(2))
    temp.removeFirst(2)
    let day = Int(temp.prefix(2))

    return DateComponents(calendar: calendar, year: year, month: month, day: day)
  }
}
