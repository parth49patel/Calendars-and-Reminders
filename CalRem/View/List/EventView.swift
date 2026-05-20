//
//  EventView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-11.
//

import SwiftUI
import EventKit
import WidgetKit

struct EventView: View {
	
	@State private var event: EKEvent?
	@Environment(\.dismiss) private var dismiss
	
	var ekManager: EventKitManager
	var existingEvent: EKEvent?
	var mode: EventViewMode = .add
	var isEditing: Bool { mode == .edit }
	
	@State private var title: String = ""
	@State private var isAllDay: Bool = false
	@State private var startDate: Date = Date()
	@State private var endDate: Date = Date().addingTimeInterval(3600)
	@State private var selectedCalendar: EKCalendar?
	@State private var notes: String = ""
	@State private var saved: Bool = false
	@State private var closed: Bool = false
	
    var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Title", text: $title)
				}
				
				Section {
					Toggle("All Day", isOn: $isAllDay)
					if !isAllDay {
						DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
						DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
					} else {
						DatePicker("Start", selection: $startDate, displayedComponents: [.date])
					}
				}
				Section {
					Picker("Calendar", selection: $selectedCalendar) {
						ForEach(ekManager.availableCalendars, id: \.calendarIdentifier) { calendar in
							Text("\(calendar.title)")
								.foregroundStyle(Color(cgColor: calendar.cgColor))
								.tag(Optional(calendar))
						}
					}
					.pickerStyle(.menu)
					.disabled(isEditing)
				}
				Section {
					TextField("Notes", text: $notes, axis: .vertical)
						.lineLimit(4...8)
				}
			}
			.navigationTitle(isEditing ? "Edit Event" : "Add Event")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar { toolbarContent }
			.onAppear { load() }
		}
    }
	
	// MARK: - Toolbar
	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .confirmationAction) {
			Button(role: .confirm) {
				save()
				saved = true
				dismiss()
			}
			.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			.sensoryFeedback(.success, trigger: saved)
		}
		ToolbarItem(placement: .cancellationAction) {
			Button(role: .close) {
				closed = true
				dismiss()
			}
			.sensoryFeedback(.stop, trigger: closed)
		}
	}
	
	private func load() {
		guard let event = existingEvent else { return }
		title = event.title
		isAllDay = event.isAllDay
		startDate = event.startDate
		endDate = event.endDate
		notes = event.notes ?? ""
		selectedCalendar = event.calendar
	}
	
	private func save() {
		let event = existingEvent ?? EKEvent(eventStore: ekManager.store)
		event.title = title
		event.startDate = startDate
		event.endDate = isAllDay ? Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)! : endDate
		event.isAllDay = isAllDay
		event.notes = notes
		if existingEvent == nil {
			event.calendar = selectedCalendar ?? ekManager.store.defaultCalendarForNewEvents
		}
		
		do {
			try ekManager.store.save(event, span: .thisEvent, commit: true)
			Task { await ekManager.refresh() }
			WidgetCenter.shared.reloadAllTimelines()
			dismiss()
		} catch {
			print("Failed to save event: \(error)")
		}
	}
}

#Preview {
	EventView(ekManager: EventKitManager())
}
