//
//  CalRemWidget.swift
//  CalRemWidget
//
//  Created by Parth Patel on 2026-05-11.
//

import WidgetKit
import SwiftUI
import EventKit
import AppIntents

// MARK: - Timeline Entry
struct UnifiedWidgetEntry: TimelineEntry {
	let date: Date
	let items: [CalendarItem]
	let permissionGranted: Bool
}

// MARK: - Timeline Provider
struct UnifiedWidgetProvider: TimelineProvider {

	func placeholder(in context: Context) -> UnifiedWidgetEntry {
		UnifiedWidgetEntry(date: Date(), items: [], permissionGranted: true)
	}

	func getSnapshot(in context: Context, completion: @escaping (UnifiedWidgetEntry) -> ()) {
		let entry = UnifiedWidgetEntry(date: Date(), items: [], permissionGranted: true)
		completion(entry)
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		Task { @MainActor in
			let result = await EventKitDataService.fetch()

			guard result.permissionGranted else {
				completion(Timeline(entries: [
					UnifiedWidgetEntry(date: .now, items: [], permissionGranted: false)
				], policy: .atEnd))
				return
			}

			let pendingItems = result.allTodayItems.filter { item in
				switch item {
				case .event(let event): return event.isAllDay || event.endDate > .now
				case .reminder(let reminder): return !reminder.isCompleted
				}
			}

			let entry = UnifiedWidgetEntry(date: .now, items: pendingItems, permissionGranted: true)
			completion(Timeline(entries: [entry], policy: .after(EventKitDataService.nextUpdate())))
		}
	}
}

// MARK: - Widget View
struct UnifiedWidgetEntryView: View {
	var entry: UnifiedWidgetProvider.Entry
	
	@Environment(\.widgetFamily) var family
	var maxItems: Int {
		switch family {
		case .accessoryRectangular: return 2
		default: return 4
		}
	}
	
	private var allItemsDone: Bool {
		entry.items.allSatisfy { item in
			switch item {
				case .event(let event) : return event.endDate < Date.now
				case .reminder(let reminder): return reminder.isCompleted
			}
		}
	}
	
	var body: some View {
		switch family {
			case .accessoryRectangular:
				accessoryRectangleView
			default:
				Group {
					if !entry.permissionGranted {
						ContentUnavailableView("Permission Not Granted", systemImage: "lock", description: Text("Calendar and Reminder access needed."))
					} else if allItemsDone {
						allDoneView
					} else if entry.items.isEmpty {
						emptyItem
					} else {
						VStack(alignment: .leading, spacing: 5) {
							HStack(alignment: .center) {
								Text(Date.now.formatted(date: .abbreviated, time: .omitted))
								Spacer()
								Text("\(entry.items.count) items")
							}
							.font(.system(size: 14, weight: .bold, design: .rounded))
							.foregroundStyle(.primary.opacity(0.6))
							.kerning(0.5)
							
							Divider()
								.overlay(.primary)

							ForEach(entry.items.prefix(maxItems)) { item in
								itemRow(for: item)
							}
						}
						.frame(maxHeight: .infinity, alignment: .top)
					}
				}
		}
	}
	
	@ViewBuilder
	private func itemRow(for item: CalendarItem) -> some View {		
		switch item {
		case .event(let event):
				HStack(alignment: .center, spacing: 10) {
				Image(systemName: "calendar")
				   .font(.system(size: 16, weight: .medium))
				   .foregroundStyle(.accent)
				   .frame(width: 16)
				
				Text(item.title)
					.font(.system(size: 16, weight: .semibold, design: .rounded))
					.lineLimit(1)
					
				Spacer()
				
					if event.isAllDay {
						Text("All Day")
							.font(.system(size: 12, weight: .medium, design: .rounded))
							.foregroundStyle(.accent)
							.padding(.horizontal, 6)
							.padding(.vertical, 2)
							.background(.accent.opacity(0.2), in: Capsule())
					} else {
						Text(event.startDate..<event.endDate, format: .interval.hour().minute())
							.font(.system(size: 12, weight: .medium, design: .rounded))
							.foregroundStyle(.accent)
							.padding(.horizontal, 6)
							.padding(.vertical, 2)
							.background(.accent.opacity(0.2), in: Capsule())
					}
				}
				.padding(.vertical, 4)
				
		case .reminder(let reminder):
			HStack(spacing: 10) {
				Button(intent: ToggleReminderIntent(reminderID: reminder.calendarItemIdentifier)) {
					Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(reminder.isCompleted ? .green : .gray)
						.symbolEffect(.pulse, value: reminder.isCompleted)
				}
				.buttonStyle(.plain)
				.frame(width: 16)
				
				Text(item.title)
					.font(.system(size: 16, weight: .semibold, design: .rounded))
					.lineLimit(1)
					.foregroundStyle(reminder.isCompleted ? .tertiary : .primary)
					.strikethrough(reminder.isCompleted, color: .secondary)
				
				Spacer()
				
				if let due = reminder.dueDateComponents?.date {
					Text(due, style: .time)
						.font(.system(size: 12, weight: .medium, design: .rounded))
						.foregroundStyle(due < Date.now ? .red : .blue)
						.padding(.horizontal, 6)
						.padding(.vertical, 2)
						.background(due < Date.now ? .red.opacity(0.2) : .blue.opacity(0.2), in: Capsule())
				} else {
					Text("No Due Date")
						.font(.system(size: 12, weight: .medium, design: .rounded))
						.foregroundStyle(.secondary)
						.padding(.horizontal, 6)
						.padding(.vertical, 2)
						.background(.quaternary, in: Capsule())
				}
			}
			.padding(.vertical, 4)
		}
	}
	
	private var emptyItem: some View {
		VStack(spacing: 6) {
			Image(systemName: "sparkle")
				.font(.system(size: 44, weight: .medium))
				.foregroundStyle(.accent)
			Text("All clear today")
				.font(.system(size: 20, weight: .semibold, design: .rounded))
				.foregroundStyle(.primary)
			Text("Nothing scheduled")
				.font(.system(size: 16, weight: .medium, design: .rounded))
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	private var allDoneView: some View {
		VStack(spacing: 6) {
			Image(systemName: "checkmark.circle.fill")
				.font(.system(size: 44, weight: .medium))
				.foregroundStyle(.green)
			Text("All done!")
				.font(.system(size: 20, weight: .semibold, design: .rounded))
				.foregroundStyle(.primary)
			Text("No more events/reminders left to do!")
				.font(.system(size: 16, weight: .medium, design: .rounded))
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	private var accessoryRectangleView: some View {
		VStack(alignment: .leading, spacing: 3) {
			if entry.items.isEmpty {
				Label("All Completed", systemImage: "checkmark.circle.fill")
					.font(.system(size: 12, weight: .semibold, design: .rounded))
			} else {
				ForEach(entry.items.prefix(3)) { item in
					HStack(spacing: 6) {
						switch item {
							case .event(_):
								Image(systemName: "calendar")
							case .reminder(let reminder):
								Button(intent: ToggleReminderIntent(reminderID: reminder.calendarItemIdentifier)) {
									Image(systemName: "circle")
								}
								.buttonStyle(.plain)
						}
						Text(item.title)
							.font(.system(size: 16, weight: .medium, design: .rounded))
							.lineLimit(1)
					}
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
	}
}

// MARK: - Widget Configuration
struct UnifiedWidget: Widget {
	let kind: String = "UnifiedWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: UnifiedWidgetProvider()) { entry in
			UnifiedWidgetEntryView(entry: entry)
				.containerBackground(Color(.secondarySystemFill), for: .widget)
		}
		.configurationDisplayName("Today's Timeline")
		.description("A unified view of your upcoming events and reminders.")
		.supportedFamilies([.systemMedium, .accessoryRectangular])
	}
}

// MARK: - Preview
#Preview(as: .systemMedium) {
	UnifiedWidget()
} timeline: {
	UnifiedWidgetEntry(date: .now, items: [], permissionGranted: true)
}
