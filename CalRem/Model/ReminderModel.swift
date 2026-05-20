//
//  ReminderModel.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-07.
//

import Foundation
import EventKit

struct ReminderModel: Identifiable {
	let id: String
	let ekIdentifier: String
	let underlyingReminder: EKReminder

	var title: String
	var dueDate: Date?
	var isCompleted: Bool
	var completionDate: Date?
	var notes: String?
	
	init(from reminder: EKReminder) {
		self.id = reminder.calendarItemIdentifier
		self.ekIdentifier = reminder.calendarItemIdentifier
		self.underlyingReminder = reminder

		self.title = reminder.title
		self.dueDate = reminder.dueDateComponents?.date
		self.isCompleted = reminder.isCompleted
		self.completionDate = reminder.completionDate
		self.notes = reminder.notes
	}
}
