//
//  WeekGlanceWidget.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-15.
//

import SwiftUI
import Charts
import WidgetKit
import EventKit

// MARK: - Timeline Entry
struct WeekGlanceEntry: TimelineEntry {
	let date: Date
	let days: [DayData]
	let permissionGranted: Bool
	
	struct DayData: Identifiable {
		let id = UUID()
		let date: Date
		let eventCount: Int
		let reminderCount: Int
		
		var dayName: String {
			Calendar.current.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
		}
		
		var total: Int { eventCount + reminderCount }
		var isToday: Bool { Calendar.current.isDateInToday(date) }
	}
}

// MARK: - Timeline Provider
struct WeekGlanceTimelineProvider: TimelineProvider {
	
	func placeholder(in context: Context) -> WeekGlanceEntry {
		WeekGlanceEntry(date: Date(), days: Self.MockDays(), permissionGranted: true)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (WeekGlanceEntry) -> Void) {
		completion(WeekGlanceEntry(date: Date(), days: Self.MockDays(), permissionGranted: true))
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<WeekGlanceEntry>) -> Void) {
		Task {
			let result = await EventKitDataService.fetch()
			guard result.permissionGranted else {
				completion(Timeline(entries: [WeekGlanceEntry(date: .now, days: [], permissionGranted: false)], policy: .atEnd))
				return
			}
			
			let days = Self.buildWeekData(from: result)
			let entry = WeekGlanceEntry(date: .now, days: days, permissionGranted: true)
			completion(Timeline(entries: [entry], policy: .after(EventKitDataService.nextUpdate())))
		}
	}
	
	static func buildWeekData(from result: EventKitFetchResult) -> [WeekGlanceEntry.DayData] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		
		return(0..<7).map { offset in
			let day = calendar.date(byAdding: .day, value: offset, to: today)!
			let isToday = offset == 0
			
			let dayItems = result.allWeekItems.filter { item in
				switch item {
					case .event(let event): return calendar.isDate(event.startDate, inSameDayAs: day)
					case .reminder(let reminder): guard let components = reminder.dueDateComponents,
														let due = calendar.date(from: components) else { return isToday }
						if isToday {
							return calendar.isDate(due, inSameDayAs: day) || due < today
						} else {
							return calendar.isDate(due, inSameDayAs: day)
						}
				}
			}
			
			let eventCount = dayItems.filter { if case .event = $0 { return true}; return false }.count
			let reminderCount = dayItems.filter { if case .reminder = $0 { return true}; return false }.count
			
			return WeekGlanceEntry.DayData(date: day, eventCount: eventCount, reminderCount: reminderCount)
		}
	}
	
	static func MockDays() -> [WeekGlanceEntry.DayData] {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: .now)
		return(0..<7).map { offset in
			let date = calendar.date(byAdding: .day, value: offset, to: today)!
			return WeekGlanceEntry.DayData(date: date, eventCount: Int.random(in: 0...3), reminderCount: Int.random(in: 0...2))
		}
	}
}

// MARK: - Widget View

private struct ChartBar: Identifiable {
	let id = UUID()
	let day: String
	let sortIndex: Int
	let count: Int
	let type: String
	let date: Date
}

struct WeekGlanceWidgetView: View {
	var entry: WeekGlanceTimelineProvider.Entry
	@Environment(\.widgetFamily) var family
	
	var totalReminders: Int {
		return entry.days.reduce(0) { $0 + $1.reminderCount }
	}
	
	var totalEvents: Int {
		return entry.days.reduce(0) { $0 + $1.eventCount }
	}
	
    var body: some View {
		Group {
			if !entry.permissionGranted {
				ContentUnavailableView("Access Denied", systemImage: "lock", description: Text("Calendar and Reminder access needed."))
			} else {
				switch family {
					case .systemLarge: largeView
					default: mediumView
				}
			}
		}
    }
	
	@ViewBuilder
	private var mediumView: some View {
		VStack(alignment: .leading, spacing: 6) {
			header
						
			Chart(chartBars) { bar in
				BarMark(x: .value("Day", bar.day), y: .value("Count", bar.count))
					.foregroundStyle(by: .value("Type", bar.type))
					.cornerRadius(4)
					.annotation(position: .overlay) {
						Text(bar.count == 0 ? "" : "\(bar.count)")
							.font(.system(size: 12, weight: .semibold, design: .rounded))
							.foregroundStyle(.secondary)
					}
			}
			.chartForegroundStyleScale(["Events": Color(red: 0.25, green: 0.60, blue: 0.95), "Reminders": Color(red: 0.95, green: 0.72, blue: 0.18)])
			.chartLegend(position: .top, alignment: .trailing)
			.chartXAxis {
				AxisMarks { value in
					AxisValueLabel {
						if let day = value.as(String.self) {
							Text(day)
								.font(.system(size: 10, weight: isToday(day) ? .bold : .medium, design: .rounded))
								.foregroundStyle(isToday(day) ? Color.accentColor : Color.secondary)
						}
					}
					AxisGridLine()
				}
			}
			.chartYAxis(.hidden)
			.frame(maxHeight: .infinity)
		}
	}
	
	private var largeView: some View {
		VStack(alignment: .leading, spacing: 8) {
			header
			
			Chart(chartBars) { bar in
				BarMark(x: .value("Count", bar.count), y: .value("Day", bar.day))
					.foregroundStyle(by: .value("Type", bar.type))
					.cornerRadius(4)
					.annotation(position: .overlay) {
						Text(bar.count == 0 ? "" : "\(bar.count)")
							.font(.system(size: 12, weight: .semibold, design: .rounded))
							.foregroundStyle(.secondary)
					}
			}
			.chartForegroundStyleScale(["Events": Color(red: 0.25, green: 0.60, blue: 0.95), "Reminders": Color(red: 0.95, green: 0.72, blue: 0.18)])
			.chartLegend(position: .top, alignment: .trailing)
			.chartXAxis(.hidden)
			.chartYAxis {
				AxisMarks { value in
					AxisValueLabel {
						if let day = value.as(String.self) {
							Text(day)
								.font(.system(size: 12, weight: isToday(day) ? .bold : .medium, design: .rounded))
								.foregroundStyle(isToday(day) ? Color.accentColor : Color.secondary)
						}
					}
					AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
				}
			}
			.frame(maxHeight: .infinity)
		}
	}
	
	private var header: some View {
		HStack {
			Text(Date.now.formatted(date: .abbreviated, time: .omitted))
				.font(.system(size: 14, weight: .bold, design: .rounded))
				.foregroundStyle(.primary.opacity(0.6))
				.kerning(0.5)
			Spacer()
			Text("\(totalEvents + totalReminders) items")
				.font(.system(size: 14, weight: .bold, design: .rounded))
				.foregroundStyle(.primary.opacity(0.6))
		}
	}
	
   private var chartBars: [ChartBar] {
	   entry.days.enumerated().flatMap { index, day in [
		ChartBar(day: day.dayName, sortIndex: index, count: day.eventCount, type: "Events", date: day.date),
		ChartBar(day: day.dayName, sortIndex: index, count: day.reminderCount, type: "Reminders", date: day.date)
	   ]}
   }

   private func isToday(_ dayName: String) -> Bool {
	   entry.days.first { $0.dayName == dayName }?.isToday ?? false
   }
}

// MARK: - Widget Configuration
struct WeekGlanceWidget: Widget {
	let kind = "WeekGlanceWidget"
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: WeekGlanceTimelineProvider()) { entry in
			WeekGlanceWidgetView(entry: entry)
				.containerBackground(.accent.quinary.opacity(0.5), for: .widget)
		}
		.configurationDisplayName("Week Glance")
		.description("See your events and reminders for the week.")
		.supportedFamilies([.systemMedium, .systemLarge])
	}
}
