//
//  MockDate.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-10.
//

import Foundation
import EventKit
import UIKit

struct MockData {
	static let store = EKEventStore()
	
	static var sampleReminder: EKReminder {
		let reminder = EKReminder(eventStore: store)
		reminder.title = "Review App UI"
		reminder.notes = "Check the padding on the expandable cards."
		reminder.isCompleted = false
		//reminder.completionDate = Date.now
		reminder.dueDateComponents = DateComponents(year: 2026, month: 5, day: 11, hour: 14, minute: 0)
		return reminder
	}
	
	static var sampleReminderUpcoming: EKReminder {
		let reminder = EKReminder(eventStore: store)
		reminder.title = "Complete Project Report"
		reminder.notes = "Check the padding on the expandable cards."
		reminder.isCompleted = false
		reminder.dueDateComponents = DateComponents(year: 2026, month: 5, day: 11, hour: 14, minute: 0)
		return reminder
	}
	
	static var completedReminder: EKReminder {
		let reminder = EKReminder(eventStore: store)
		reminder.title = "Finish Initial Setup"
		reminder.isCompleted = true
		return reminder
	}
	
	static var sampleEvent: EKEvent {
		let event = EKEvent(eventStore: store)
		event.title = "Team Meeting"
		event.startDate = Date(timeIntervalSinceNow: 3600)
		event.endDate = Date(timeIntervalSinceNow: 7200)
		event.notes = "Discuss Q3 plans"
		event.isAllDay = false
		let calendar = EKCalendar(for: .event, eventStore: store)
		calendar.title = "Work"
		calendar.cgColor = UIColor.systemBlue.cgColor
		event.calendar = calendar
		return event
	}
}
