//
//  ToggleReminderIntent.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-12.
//

import AppIntents
import EventKit
import WidgetKit

struct ToggleReminderIntent: AppIntent {
	static var title: LocalizedStringResource = "Toggle Reminder"
	
	@Parameter(title: "Reminder ID")
	var reminderID: String
	
	init() { }
	init(reminderID: String) {
		self.reminderID = reminderID
	}
	func perform() async throws -> some IntentResult {
		let store = EKEventStore()
		
		guard let reminder = await withCheckedContinuation ({ continuation in
			store.fetchReminders(matching: store.predicateForReminders(in: nil)) { reminders in
				let match = reminders?.first { $0.calendarItemIdentifier == reminderID }
				continuation.resume(returning: match)
			}
		}) else { return .result() }
		
		reminder.isCompleted = !reminder.isCompleted
		reminder.completionDate = reminder.isCompleted ? Date() : nil
		try store.save(reminder, commit: true)
		WidgetCenter.shared.reloadAllTimelines()
		
		return .result()
	}
}
