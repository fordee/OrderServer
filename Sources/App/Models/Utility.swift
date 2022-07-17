//
//  File.swift
//  
//
//  Created by John Forde on 24/06/22.
//

import Foundation

extension String {
  func sanitized() -> String {
    // see for ressoning on charachrer sets https://superuser.com/a/358861
    let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
      .union(.newlines)
      .union(.illegalCharacters)
      .union(.controlCharacters)

    return self
      .components(separatedBy: invalidCharacters)
      .joined(separator: "")
  }

  mutating func sanitize() -> Void {
    self = self.sanitized()
  }

  func whitespaceCondensed() -> String {
    return self.components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }

  mutating func condenseWhitespace() -> Void {
    self = self.whitespaceCondensed()
  }
}

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
