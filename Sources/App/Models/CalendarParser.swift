//
//  CalendarParser.swift
//  ShopAdmin
//
//  Created by John Forde on 12/07/22.
//

//import Foundation
//import CLibical
//import SwiftIcal
//
//
//struct CalendarParser {
//
//  var fileContents: String = ""
//
//  var events: [VEvent] = []
//
//  init(_ fileContents: String) {
//    self.fileContents = fileContents
//  }
//
//  mutating func parseIcalFile() {
//
//    if let calendar = try? VCalendar.parseEvents(fileContents) {
//      print("Calendar \(calendar.icalString())")
//      events = calendar.events
//    } else {
//      print("Parse failed")
//    }
//
//  }
//}
//
//// The following parse method and redeclatation of some Swift-iCal properties because it doesn't parse VEvents in the iCal file.
//// (Which seems to be the whole point in my opinion.)
//
//typealias LibicalComponent = OpaquePointer
//typealias LibicalProperty = OpaquePointer
//
//extension LibicalComponent {
//    subscript(kind: icalproperty_kind) -> [LibicalProperty] {
//        var result: [LibicalProperty] = []
//        if let first = icalcomponent_get_first_property(self, kind) {
//            result.append(first)
//        }
//        while let property = icalcomponent_get_next_property(self, kind) {
//            result.append(property)
//        }
//        return result
//    }
//
//    subscript(kind: icalcomponent_kind)-> [LibicalComponent] {
//        var result: [LibicalComponent] = []
//        if let first = icalcomponent_get_first_component(self, kind) {
//            result.append(first)
//        }
//        while let property = icalcomponent_get_next_component(self, kind) {
//            result.append(property)
//        }
//        return result
//    }
//}
//
//extension LibicalProperty {
//    var value: String? {
//        guard let ptr = icalproperty_get_value_as_string(self) else {
//            return nil
//        }
//        return String(cString: ptr)
//    }
//}
//
//
//extension VCalendar {
//    public static func parseEvents(_ string: String) throws -> VCalendar {
//        guard let calendarComponent: LibicalComponent = icalcomponent_new_from_string(string) else {
//            throw ParseError.invalidVCalendar
//        }
//      
//        var calendar = VCalendar()
//        // Parse Prodid
//        if let prodid = calendarComponent[ICAL_PRODID_PROPERTY].first?.value {
//            calendar.prodid = prodid
//        }
//
//        // Parse Version
//        guard let version = calendarComponent[ICAL_VERSION_PROPERTY].first?.value else {
//            throw ParseError.noVersion
//        }
//        if version != "2.0" {
//            throw ParseError.invalidVersion
//        }
//
//        let iCalEvents = calendarComponent[ICAL_VEVENT_COMPONENT]
//
//        iCalEvents.forEach { event in
//          if let startDateString = event[ICAL_DTSTART_PROPERTY].first?.value,
//             let endDateString = event[ICAL_DTEND_PROPERTY].first?.value,
//             let uid = event[ICAL_UID_PROPERTY].first?.value,
//             let description = event[ICAL_DESCRIPTION_PROPERTY].first?.value,
//             let summary = event[ICAL_SUMMARY_PROPERTY].first?.value {
//
//            let startDate = startDateString.stringToDateComponents()
//            let endDate = endDateString.stringToDateComponents()
//            var iCalEvent = VEvent(summary: summary, dtstart: startDate, dtend: endDate)
//            iCalEvent.description = description
//            iCalEvent.uid = uid
//            calendar.events.append(iCalEvent)
//          }
//
//        }
//        return calendar
//    }
//}
//
