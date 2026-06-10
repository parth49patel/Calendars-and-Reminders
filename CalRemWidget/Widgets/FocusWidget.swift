//
//  FocusWidget.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-21.
//

import SwiftUI
import WidgetKit
import EventKit

// MARK: - Timeline Entry
struct FocusWidgetEntry: TimelineEntry {
	let date: Date
	let title: String
	let targetDate: Date?
	let color: Color
	let isEvent: Bool
	let isClear: Bool
	let permissionGranted: Bool
}

// MARK: - Timeline Provider
struct FocusTimelineProvider: TimelineProvider {
	func placeholder(in context: Context) -> FocusWidgetEntry {
		FocusWidgetEntry(date: .now, title: "Design a Widget", targetDate: .now.addingTimeInterval(3600), color: .purple, isEvent: true, isClear: false, permissionGranted: true)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
		completion(FocusWidgetEntry(date: .now, title: "Design a Widget", targetDate: .now.addingTimeInterval(3600), color: .purple, isEvent: true, isClear: false, permissionGranted: true))
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
		Task {
			let result = await EventKitDataService.fetch()
			guard result.permissionGranted else {
				completion(Timeline(entries: [FocusWidgetEntry(date: .now, title: "", targetDate: .now, color: .accent, isEvent: false, isClear: true, permissionGranted: false)], policy: .atEnd))
				return
			}
			
			let entry = Self.buildFocusDate(from: result)
			completion(Timeline(entries: [entry], policy: .after(EventKitDataService.nextUpdate())))
		}
	}
	
	static func buildFocusDate(from result: EventKitFetchResult) -> FocusWidgetEntry {
		let now = Date.now
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: now)
		
		let activeItems = result.allTodayItems.filter { item in
			switch item {
				case .event(let event):
					return calendar.isDate(event.startDate, inSameDayAs: today)
				case .reminder(let reminder):
					guard !reminder.isCompleted else { return false }
					if let components = reminder.dueDateComponents, let due = calendar.date(from: components) {
						return due < today || calendar.isDate(due, inSameDayAs: today)
					}
					return true
			}
		}
		let focusItem: CalendarItem? = {
			if let inProgress = activeItems.first(where: {
				guard case .event(let e) = $0 else { return false }
				return e.startDate <= now && e.endDate > now
			}) { return inProgress}
			
			if let soon = activeItems.first(where: {
				guard case .event(let e) = $0 else { return false }
				return e.startDate > now && e.startDate.timeIntervalSince(now) < 1800
			}) { return soon }
			
			if let overdue = activeItems.first(where: {
				guard case .reminder(let r) = $0,
					let components = r.dueDateComponents,
					  let due = calendar.date(from: components) else { return false }
				return due < today
			}) { return overdue }
			
			return activeItems.first(where: {
				switch $0 {
					case .event(let e): return e.startDate > now
					case .reminder(let r): return r.dueDateComponents?.date != nil || !r.isCompleted
				}
			})
		}()
		
		if let item = focusItem {
			var color: Color = .blue
			var targetDate: Date? = nil
			var isEvent = true
			
			switch item {
				case .event(let e):
					isEvent = true
					targetDate = e.startDate
					color = .accent
//					if let cgColor = e.calendar?.cgColor {
//						color = Color(cgColor: cgColor)
//					}
				case .reminder(let r):
					isEvent = false
					targetDate = r.dueDateComponents?.date
					color = .accent
			}
			return FocusWidgetEntry(date: now, title: item.title, targetDate: targetDate, color: color, isEvent: isEvent, isClear: false, permissionGranted: true)
		}
		return FocusWidgetEntry(date: now, title: "All Clear", targetDate: nil, color: .green, isEvent: false, isClear: true, permissionGranted: true)
	}
}

// MARK: - Widget View
struct FocusWidgetView: View {
	var entry: FocusTimelineProvider.Entry
	
	var body: some View {
		Group {
			if !entry.permissionGranted {
				ContentUnavailableView("Access Denied", systemImage: "lock", description: Text("Calendar and Reminder access needed."))
			} else if entry.isClear {
				clearView
			} else {
				focusView
			}
		}
	}
	
	// MARK: Clear View
	private var clearView: some View {
		VStack(spacing: 6) {
			Image(systemName: "checkmark.circle.fill")
				.font(.system(size: 44, weight: .medium))
				.foregroundStyle(.green)
			Text("All done!")
				.font(.system(size: 20, weight: .semibold, design: .rounded))
				.foregroundStyle(.primary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	private var focusView: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 5) {
				Image(systemName: entry.isEvent ? "calendar" : "checklist.unchecked")
				Text(entry.isEvent ? "UP NEXT" : "REMINDER")
			}
			.foregroundStyle(entry.color)
			.font(.system(size: 12, weight: .semibold, design: .rounded))
			.kerning(0.5)
			
			RoundedRectangle(cornerRadius: 2)
				.fill(entry.color)
				.frame(height: 2)

			Text(entry.title)
				.font(.system(size: 18, weight: .bold, design: .rounded))
				.lineLimit(3)
				.foregroundStyle(.accent)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			
			HStack {
				if let target = entry.targetDate {
					Text(target.formatted(date: .abbreviated, time: .shortened))
				} else if !entry.isEvent {
					Text("No Due Date")
				}
			}
			.font(.system(size: 12, weight: .semibold, design: .rounded))
			.frame(maxWidth: .infinity)
			.foregroundStyle(entry.color)
			.padding(.horizontal, 4)
			.padding(.vertical, 4)
			.background(entry.color.opacity(0.12), in: Capsule())
		}
	}
}

// MARK: - Widget Configuration
struct FocusWidget: Widget {
	let kind = "FocusWidget"
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: FocusTimelineProvider()) { entry in
			FocusWidgetView(entry: entry)
				.containerBackground(.accent.quaternary.opacity(0.3), for: .widget)
		}
		.configurationDisplayName(Text("Focus"))
		.description("")
		.supportedFamilies([.systemSmall])
	}
}
