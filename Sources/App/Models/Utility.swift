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
