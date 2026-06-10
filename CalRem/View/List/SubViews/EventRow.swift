//
//  EventRow.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-05.
//

import SwiftUI
import EventKit

struct EventRow: View {
	
	let event: EKEvent
	let ekManager: EventKitManager
	
	@State private var isExpanded: Bool
	
	private static func shouldAutoExpand(_ event: EKEvent) -> Bool {
		guard let date = event.startDate else { return false }
		return Calendar.current.isDateInToday(date)
	}
    
	init(event: EKEvent, ekManager: EventKitManager) {
		self.event = event
		self.ekManager = ekManager
		self._isExpanded = .init(initialValue: Self.shouldAutoExpand(event))
	}
	
	var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: 8) {
			Image(systemName: "calendar")
				.font(.system(size: 20, weight: .semibold))
				.foregroundStyle(Color(cgColor: event.calendar.cgColor))
				.frame(width: 44, height: 44)
			
			VStack(alignment: .leading, spacing: 6) {
				Text(event.title ?? "New Event")
					.font(.system(size: isExpanded ? 18 : 16, design: .rounded))
					.foregroundStyle(event.endDate < Date() ? .secondary : .primary)
					.bold(isExpanded)
					.strikethrough(event.endDate < Date(), color: .secondary)
					.lineLimit((isExpanded || event.endDate > Date()) ? 2 : 1)
				
					if event.isAllDay {
						Text("All Day")
							.font(.system(size: isExpanded ? 14 : 12, weight: .medium, design: .rounded))
							.foregroundStyle(Color(cgColor: event.calendar.cgColor))
							.padding(.horizontal, 8)
							.padding(.vertical, 2)
							.background(Color(cgColor: event.calendar.cgColor).opacity(0.15), in: Capsule())
					} else {
							Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.endDate.formatted(date: .omitted, time: .shortened))")
						
							.font(.system(size: isExpanded ? 14 : 12, weight: .medium, design: .rounded))
							.foregroundStyle(Color(cgColor: event.calendar.cgColor))
							.padding(.horizontal, 8)
							.padding(.vertical, 2)
							.background(Color(cgColor: event.calendar.cgColor).opacity(0.15), in: Capsule())
					}
				
				if isExpanded, let note = event.notes, !note.isEmpty {
				   Text(note)
						.font(.system(size: 13, design: .rounded))
						.foregroundStyle(.secondary)
						.lineLimit(3)
						.padding(.top, 2)
				}
			}
		}
    }
}

#Preview("Today") {
	EventRow(event: MockData.sampleEvent, ekManager: EventKitManager())
}
