//
//  EventKitDataService.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-15.
//

import EventKit
import WidgetKit

struct EventKitFetchResult {
	let allTodayItems: [CalendarItem]
	let allWeekItems: [CalendarItem]
	let permissionGranted: Bool
}

struct EventKitDataService {
	
	static func checkPermission() -> Bool {
		EKEventStore.authorizationStatus(for: .event) == .fullAccess && EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
	}
	
	@MainActor
	static func fetch() async -> EventKitFetchResult {
		guard checkPermission() else {
			return EventKitFetchResult(allTodayItems: [], allWeekItems: [], permissionGranted: false)
		}
	 
		let ekManager = EventKitManager()
		ekManager.fetchAvailableCalendars()
		await ekManager.refresh()
		
		let calendar = Calendar.current
		let allItems = ekManager.unifiedItems
		
		let todayItems = allItems.filter { item in
			switch item {
				case .event(let event):
					return calendar.isDateInToday(event.startDate)
				case .reminder(let reminder):
					guard let components = reminder.dueDateComponents,
						  let due = calendar.date(from: components) else { return true }
					return calendar.isDateInToday(due) || (due < .now && !reminder.isCompleted)
			}
		}
		let today = calendar.startOfDay(for: .now)
		let sevenDaysLater = calendar.date(byAdding: .day, value: 7, to: today)!
		
		let weekItems = allItems.filter { item in
			switch item {
				case .event(let event):
					return event.startDate >= today && event.startDate < sevenDaysLater
				case .reminder(let reminder):
					guard let components = reminder.dueDateComponents,
						  let due = calendar.date(from: components) else { return true }
					return (due >= today && due < sevenDaysLater) || (due < .now && !reminder.isCompleted)
			}
		}
		
		return EventKitFetchResult(allTodayItems: todayItems, allWeekItems: weekItems, permissionGranted: true)
	}
	
	static func nextUpdate() -> Date {
		Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
	}
}
