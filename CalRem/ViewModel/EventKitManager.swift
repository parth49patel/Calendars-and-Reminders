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
	
	var permissionGranted: Bool = false
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

		let grouped = Dictionary(grouping: unifiedItems) { item -> Date in
			if item.sortDate == Date.distantFuture { return today }
			let itemDate = calendar.startOfDay(for: item.sortDate)
			if case .reminder(let rem) = item, !rem.isCompleted, itemDate < today {
				return today
			}
			return itemDate
		}
		return grouped
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
			permissionGranted = true
			fetchAvailableCalendars()
		} catch {
			print("Permission Denied: \(error)")
			permissionGranted = false
		}
	}
	
	func refresh() async {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: Date())
		let end = calendar.date(byAdding: .day, value: preferences.upcomingDaysLimit, to: start)!
		
		self.events = fetchEvents(from: start, to: end)
		self.reminders = await fetchReminders(from: start, to: end)
		self.refreshID = UUID()
	}
	
	// MARK: - Fetch Calendars
	func fetchAvailableCalendars() {
		let calendars = store.calendars(for: .event)
		availableCalendars = calendars.filter { $0.allowsContentModifications }
		
		if !preferences.hasRunFirstLaunchSetup {
			preferences.selectedCalendarIdentifiers = Set(availableCalendars.map { $0.calendarIdentifier })
			preferences.hasRunFirstLaunchSetup = true 
		}
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
		
		if selectedCals.isEmpty && preferences.hasRunFirstLaunchSetup {
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
