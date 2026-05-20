//
//  EventModel.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-07.
//

import Foundation
import EventKit
//import SwiftData
//
//@Model
struct EventModel {
	var id: String
	var ekIdentifier: String
	var underlyingEvent: EKEvent
	
	var title: String
	var startDate: Date
	var endDate: Date
	var isAllDay: Bool
	var notes: String?
	var calendar: String
	
	init(from event: EKEvent) {
		self.id = event.eventIdentifier ?? UUID().uuidString
		self.ekIdentifier = event.eventIdentifier ?? ""
		self.underlyingEvent = event
		self.title = event.title ?? ""
		self.startDate = event.startDate
		self.endDate = event.endDate
		self.isAllDay = event.isAllDay
		self.notes = event.notes
		self.calendar = event.calendar.calendarIdentifier
	}
}
