//
//  Enums.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-11.
//

import Foundation
import EventKit

enum EventType: String, CaseIterable, Hashable, Identifiable {
	var id: String { rawValue }
	case reminder, calendar
}

enum EventViewMode {
	case add, edit
}

enum CalendarItem: Identifiable {
	case event(EKEvent)
	case reminder(EKReminder)
	
	var id: String {
		switch self {
			case .event(let event):
				return event.eventIdentifier ?? UUID().uuidString
			case .reminder(let reminder):
				return reminder.calendarItemIdentifier
		}
	}
	
	var sortDate: Date {
		switch self {
			case .event(let event):
				return event.startDate ?? Date.distantFuture
			case .reminder(let reminder):
				if reminder.isCompleted {
					if let dueDate = reminder.dueDateComponents?.date {
						return dueDate
					}
					return reminder.completionDate ?? Date.distantFuture
				}
				return reminder.dueDateComponents?.date ?? Date.distantFuture
		}
	}
	
	var title: String {
		switch self {
			case .event(let event):
				return event.title ?? "Unknown Event"
			case .reminder(let reminder):
				return reminder.title ?? "Unknown Reminder"
		}
	}
}
