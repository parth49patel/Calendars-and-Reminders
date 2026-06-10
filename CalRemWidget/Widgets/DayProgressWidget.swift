//
//  CompletionCounterWidget.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-12.
//

import SwiftUI
import WidgetKit
import EventKit

// MARK: - Timeline Entry
struct DayProgressWidgetEntry: TimelineEntry {
	let date: Date
	let progress: Double
	let totalItems: Int
	let doneItems: Int
	let permissionGranted: Bool
}

// MARK: - Timeline Provider
struct DayProgressWidgetProvider: TimelineProvider {
	
	func placeholder(in context: Context) -> DayProgressWidgetEntry {
		DayProgressWidgetEntry(date: Date(), progress: 50, totalItems: 4, doneItems: 2, permissionGranted: true)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (DayProgressWidgetEntry) -> ()) {
		let entry = DayProgressWidgetEntry(date: Date(), progress: 50, totalItems: 4, doneItems: 2, permissionGranted: true)
		completion(entry)
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		Task { @MainActor in
			let result = await EventKitDataService.fetch()
			
			guard result.permissionGranted else {
				completion(Timeline(entries: [DayProgressWidgetEntry(date: .now, progress: 0, totalItems: 0, doneItems: 0, permissionGranted: false)], policy: .atEnd))
				return
			}
			
			let done = result.allTodayItems.filter { item in
				switch item {
					case .event(let event): return event.endDate < .now
					case .reminder(let reminder): return reminder.isCompleted
				}
			}.count
			
			let total = result.allTodayItems.count
			let entry = DayProgressWidgetEntry(date: .now, progress: total > 0 ? Double(done) / Double(total) : 0.0, totalItems: total, doneItems: done, permissionGranted: true)
			completion(Timeline(entries: [entry], policy: .after(EventKitDataService.nextUpdate())))
		}
	}
}

// MARK: - Widget View
struct DayProgressWidgetEntryView: View {
	var entry: DayProgressWidgetProvider.Entry
	
	private var statusLabel: String {
		switch entry.progress {
			case 1.0: return "All done!"
			case 0.0: return "Let's go"
			default: return "Keep Going"
		}
	}
	
	private var progressColor: Color {
		switch entry.progress {
			case 1.0: return .green
			case 0.5: return .accent
			default: return .accent
		}
	}
	var body: some View {
		Group {
			if !entry.permissionGranted {
				ContentUnavailableView("Access Required", systemImage: "lock", description: Text("Calendar and Reminder access needed."))
			} else if entry.totalItems == 0 {
				emptyView
			} else  {
				progressView
			}
		}
	}
	
	@ViewBuilder
	private var emptyView: some View {
		VStack(spacing: 6) {
			Image(systemName: "checkmark.circle.fill")
				.font(.system(size: 30, weight: .medium))
			Text("All done!")
				.font(.system(size: 18, weight: .semibold, design: .rounded))
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	@ViewBuilder
	private var progressView: some View {
		ZStack {
			Circle()
				.stroke(progressColor.opacity(0.15), lineWidth: 16)
			
			Circle()
				.trim(from: 0, to: CGFloat(entry.progress))
				.stroke(progressColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
				.rotationEffect(Angle(degrees: -90))
			
			VStack(spacing: 2) {
				if entry.progress == 1.0 {
					Image(systemName: "checkmark")
						.font(.system(size: 28, weight: .bold))
						.foregroundStyle(.green)
				} else {
					Text("\(Int(round(entry.progress * 100)))%")
						.font(.system(size: 28, weight: .bold, design: .rounded))
						.foregroundStyle(.accent)
				}
				Text(statusLabel)
					.font(.system(size: 13, weight: .semibold, design: .rounded))
					.foregroundStyle(.secondary)
			}
		}
		.padding(8)
	}
}

// MARK: - Widget Configuration
struct DayProgressWidget: Widget {
	let kind = "DayProgressWidget"
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: DayProgressWidgetProvider()) { entry in
			DayProgressWidgetEntryView(entry: entry)
				.containerBackground(.accent.quinary, for: .widget)
		}
		.configurationDisplayName("Day Progress")
		.description("Track how much of your day is done.")
		.supportedFamilies([.systemSmall])
	}
}
