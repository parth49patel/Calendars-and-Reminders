//
//  EventKitManager.swift
//  CalRem
//
//  Created by Parth Patel on 2026-04-28.
//

import EventKit
import SwiftUI
import WidgetKit

@Observable
@MainActor
class EventKitManager {
	
	var store = EKEventStore()
	var preferences = PreferencesViewModel.shared
	
	var isLoading = true
	var reminderAuthStatus: EKAuthorizationStatus = .notDetermined
	var reminderGranted: Bool { reminderAuthStatus == .fullAccess }
	
	var calendarAuthStatus: EKAuthorizationStatus = .notDetermined
	var calendarGranted: Bool { calendarAuthStatus == .fullAccess }
	
	var permissionGranted: Bool { calendarGranted && reminderGranted }
	
	var events: [EKEvent] = []
	var reminders: [EKReminder] = []
	var availableCalendars: [EKCalendar] = []
	
	private(set) var refreshID: UUID = UUID()
	
	var unifiedItems: [CalendarItem] {
		let eventItems = events.map { CalendarItem.event ($0) }
		let reminderItems = reminders.map { CalendarItem.reminder ($0) }
		return (eventItems + reminderItems)
			.sorted(by: { $0.sortDate < $1.sortDate })
	}
	
	var groupedByDate: [(date: Date, items: [CalendarItem])] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())

		var result: [Date: [CalendarItem]] = [:]

		for item in unifiedItems {
			if case .event(let event) = item,
			   calendar.startOfDay(for: event.startDate) != calendar.startOfDay(for: event.endDate) {
				// Multi-day event — add to every day it spans
				var current = calendar.startOfDay(for: event.startDate)
				let end = calendar.startOfDay(for: event.endDate)
				while current <= end {
					result[current, default: []].append(item)
					current = calendar.date(byAdding: .day, value: 1, to: current)!
				}
			} else {
				// Single day event or reminder
				if item.sortDate == Date.distantFuture {
					result[today, default: []].append(item)
				} else {
					var itemDate = calendar.startOfDay(for: item.sortDate)
					if case .reminder(let rem) = item, !rem.isCompleted, itemDate < today {
						itemDate = today
					}
					result[itemDate, default: []].append(item)
				}
			}
		}

		return result
			.map { (date: $0.key, items: $0.value) }
			.sorted { $0.date < $1.date }
	}
	
	init() {
		observeChanges()
	}
	
		// MARK: - Request Permission and Refresh
	func requestPermission() async {
		do {
			try await store.requestFullAccessToReminders()
			try await store.requestFullAccessToEvents()
			checkCurrentPermissionStatus()
			
			if permissionGranted {
				fetchAvailableCalendars()
			}
		} catch {
			print("Permission Denied: \(error)")
			checkCurrentPermissionStatus()
		}
	}
	
	func checkCurrentPermissionStatus() {
		calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
		reminderAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
	}
	
	func refresh() async {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: Date())
		let end = calendar.date(byAdding: .day, value: preferences.upcomingDaysLimit, to: start)!
		
		self.events = fetchEvents(from: start, to: end)
		self.reminders = await fetchReminders(from: start, to: end)
		self.refreshID = UUID()
		self.isLoading = false
	}
	
		// MARK: - Fetch Calendars
	func fetchAvailableCalendars() {
		let calendars = store.calendars(for: .event)
		availableCalendars = calendars.filter { $0.allowsContentModifications }
	}
		///Helper function to get EKCalendar from Identifier
	func getSelectedCalendars(for entityType: EKEntityType) -> [EKCalendar] {
		let allCalendars = store.calendars(for: entityType)
		let filtered = allCalendars.filter { preferences.selectedCalendarIdentifiers.contains($0.calendarIdentifier)}
		return filtered
	}
	
	func toggleCalendar(_ id: String) {
		if preferences.selectedCalendarIdentifiers.contains(id) {
			preferences.selectedCalendarIdentifiers.remove(id)
		} else {
			preferences.selectedCalendarIdentifiers.insert(id)
		}
	}
	
	func observeChanges() {
		NotificationCenter.default.addObserver(self, selector: #selector(storeChanged), name: .EKEventStoreChanged, object: store)
	}
	
	@objc private func storeChanged() {
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 500_000_000)
			await refresh()
			WidgetCenter.shared.reloadAllTimelines()
		}
	}
}

	// MARK: - Events
extension EventKitManager {
	func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
		let selectedCals = getSelectedCalendars(for: .event)
		
		if selectedCals.isEmpty {
			return []
		}
		
		let predicate = store.predicateForEvents(
			withStart: startDate,
			end: endDate,
			calendars: selectedCals
		)
		return store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
	}
}

	// MARK: - Reminders
extension EventKitManager {
	func fetchReminders(from startDate: Date, to endDate: Date) async -> [EKReminder] {
		let calendar = Calendar.current
		
		let incompletePredicate = store.predicateForIncompleteReminders(
			withDueDateStarting: nil,
			ending: nil,
			calendars: nil
		)
		let allIncomplete: [EKReminder] = await withCheckedContinuation { continuation in
			store.fetchReminders(matching: incompletePredicate) { reminders in
				continuation.resume(returning: reminders ?? [])
			}
		}
		
		let completedPredicate = store.predicateForCompletedReminders(
			withCompletionDateStarting: nil,
			ending: nil,
			calendars: nil
		)
		let allCompleted: [EKReminder] = await withCheckedContinuation { continuation in
			store.fetchReminders(matching: completedPredicate) { reminders in
				continuation.resume(returning: reminders ?? [])
			}
		}
		let allFetched = allIncomplete + allCompleted
		return allFetched.filter { reminder in
			if reminder.isCompleted {
					// Has due date — show on due date
				if let dueComponents = reminder.dueDateComponents,
				   let dueDate = calendar.date(from: dueComponents) {
					let startOfDueDate = calendar.startOfDay(for: dueDate)
					return startOfDueDate >= startDate && startOfDueDate < endDate
				}
					// No due date — show on completion date
				else if let compDate = reminder.completionDate {
					let startOfCompDate = calendar.startOfDay(for: compDate)
					return startOfCompDate >= startDate && startOfCompDate < endDate
				}
				return false
			} else {
					// Incomplete with due date — show from due date onwards
				if let dueComponents = reminder.dueDateComponents,
				   let dueDate = calendar.date(from: dueComponents) {
					let startOfDueDate = calendar.startOfDay(for: dueDate)
					return startOfDueDate < endDate
				}
					// Incomplete no due date — always show
				return true
			}
		}
	}
		/// Mark a Reminder as complete
	func toggleReminder(_ reminder: EKReminder, isCompleted: Bool) {
		reminder.isCompleted = isCompleted
		reminder.completionDate = isCompleted ? Date() : nil
		
		do {
			try store.save(reminder, commit: true)
			print("Successfully saved to Apple Reminders: \(reminder.title ?? "") as \(isCompleted ? "Complete" : "Incomplete")")
		} catch {
			print("Failed to toggle reminder: \(error)")
		}
	}
}


	// MARK: - Analytics
extension EventKitManager {
	
		/// Calendar + Reminders for today.
	var todayItems: [CalendarItem] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		return unifiedItems.filter { item in
			switch item {
				case .event(let event):
					return calendar.isDate(event.startDate, inSameDayAs: today)
				case .reminder(let reminder):
					guard let components = reminder.dueDateComponents, let due = calendar.date(from: components) else { return true }
					return calendar.isDate(due, inSameDayAs: today) || !reminder.isCompleted
			}
		}
	}
	
		/// Calendar events for today
	var todayEvents: [CalendarItem] {
		todayItems.filter { if case .event = $0 { return true }; return false }
	}
	
		/// Reminders for today
	var todayReminders: [CalendarItem] {
		todayItems.filter { if case .reminder = $0 { return true }; return false }
	}
	
		/// Reminders + Events completed today
	var todayCompleted: [CalendarItem] {
		todayItems.filter { item in
			switch item {
				case .event(let event): return event.endDate < Date.now
				case .reminder(let reminder): return reminder.isCompleted
			}
		}
	}
	
		/// Remaining events + reminders
	var todayRemaining: [CalendarItem] {
		todayItems.filter { item in
			switch item {
				case .event(let event): return event.endDate >= Date.now
				case .reminder(let reminder): return !reminder.isCompleted
			}
		}
	}
	
		/// Today's Progress
	var todayProgress: Double {
		guard !todayItems.isEmpty else { return 0 }
		return Double(todayCompleted.count) / Double(todayItems.count)
	}
	
		/// Overdue
	var overdueItems: [CalendarItem] {
		let today = Calendar.current.startOfDay(for: .now)
		return unifiedItems.filter { item in
			guard case .reminder(let reminder) = item,
				  !reminder.isCompleted,
				  let components = reminder.dueDateComponents,
				  let due = Calendar.current.date(from: components) else { return false }
			return due < today
		}
	}
	
		/// Focus Now
	var focusNowItem: CalendarItem? {
		let now = Date.now
		
			// Event in Progress
		if let inProgress = todayItems.first(where: {
			guard case .event(let event) = $0 else { return false }
			return event.startDate <= now && event.endDate > now
		}) { return inProgress }
		
			// Event Starting in 30 mins
		if let soon = todayItems.first(where: {
			guard case .event(let event) = $0 else { return false }
			return event.startDate > now && event.startDate.timeIntervalSince(now) < 1800
		}) { return soon }
		
			// Overdue Reminder
		if let overdue = overdueItems.first { return overdue }
		
			// Next reminder due
		if let nextReminder = todayReminders.first(where: {
			guard case .reminder(let reminder) = $0 else { return false }
			return !reminder.isCompleted || reminder.dueDateComponents?.date != nil
		}) { return nextReminder }
		
			// Next upcmoing event
		return todayItems.first(where: {
			guard case .event(let event) = $0 else { return false }
			return event.startDate > now
		})
	}
	
		// Next Item Focus
	var focusNextItem: CalendarItem? {
		guard let focus = focusNowItem else { return nil }
		return todayRemaining.first { $0.id != focus.id }
	}
	
		// Conflicts
	var todayConflicts: [(EKEvent, EKEvent)] {
		let events = todayItems.compactMap { item -> EKEvent? in
			guard case .event(let event) = item, !event.isAllDay else { return nil }
			return event
		}
		var conflicts: [(EKEvent, EKEvent)] = []
		
		for i in 0..<events.count {
			for j in (i + 1)..<events.count {
				let a = events[i], b = events[j]
				if a.startDate < b.endDate && b.startDate < a.endDate {
					conflicts.append((a,b))
				}
			}
		}
		return conflicts
	}
	
	var hasConflicts: Bool { !todayConflicts.isEmpty }
}
