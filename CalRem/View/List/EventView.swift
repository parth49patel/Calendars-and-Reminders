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
	@FocusState private var focusedField: Bool

	var ekManager: EventKitManager
	var existingEvent: EKEvent?
	var mode: EventViewMode = .add
	var isEditing: Bool { mode == .edit }
	
	@State private var showErrorAlert: Bool = false
	@State private var errorMessage: String = ""
	
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
					TextField("Title", text: $title, axis: .vertical)
						.font(.system(size: 20, weight: .semibold, design: .rounded))
						.lineLimit(3)
						.focused($focusedField)
				}
				
				Section {
					Toggle(isOn: $isAllDay) {
						Label("All Day", systemImage: "sun.max.fill")
							.font(.system(size: 18, weight: .medium, design: .rounded))
					}
					
					if !isAllDay {
						DatePicker(selection: $startDate, displayedComponents: [.date, .hourAndMinute]) {
							Label("Start", systemImage: "clock")
								.font(.system(size: 18, weight: .medium, design: .rounded))
						}
						DatePicker(selection: $endDate, displayedComponents: [.date, .hourAndMinute]) {
							Label("End", systemImage: "clock.badge.checkmark")
								.font(.system(size: 18, weight: .medium, design: .rounded))
						}
					} else {
						DatePicker(selection: $startDate, displayedComponents: [.date]) {
							Label("Date", systemImage: "calendar.badge.checkmark.rtl")
								.font(.system(size: 18, weight: .medium, design: .rounded))
						}
						DatePicker(selection: $endDate, displayedComponents: [.date]) {
							Label("Date", systemImage: "calendar.badge.checkmark")
								.font(.system(size: 18, weight: .medium, design: .rounded))
						}
					}
				}
				
				Section {
					Picker(selection: $selectedCalendar) {
						ForEach(ekManager.availableCalendars, id: \.calendarIdentifier) { calendar in
							Text(calendar.title)
								.foregroundStyle(Color(cgColor: calendar.cgColor))
								.tag(Optional(calendar))
						}
					} label: {
						Label("Calendar", systemImage: "ellipsis.calendar")
							.font(.system(size: 18, weight: .medium, design: .rounded))
					}
					.pickerStyle(.menu)
					.disabled(isEditing)
				}
				Section {
					TextField("Notes", text: $notes, axis: .vertical)
						.lineLimit(4...8)
						.font(.system(size: 18, weight: .medium, design: .rounded))
						.foregroundStyle(.primary)
				}
				
				Section {
					if let existing = existingEvent, let createDate = existing.creationDate, let modifyDate = existing.lastModifiedDate {
						HStack {
							Label("Created", systemImage: "pencil.tip.crop.circle.badge.plus.fill")
								.font(.system(size: 18, weight: .medium, design: .rounded))
								.foregroundStyle(.secondary)
							
							Spacer()
							Text(createDate.formatted(date: .abbreviated, time: .shortened))
								.font(.system(size: 16, weight: .medium, design: .rounded))
								.foregroundStyle(.secondary)
						}
						if createDate != modifyDate {
							HStack {
								Label("Last Modified", systemImage: "square.and.pencil")
									.font(.system(size: 18, weight: .medium, design: .rounded))
									.foregroundStyle(.secondary)
								
								Spacer()
								
								Text(modifyDate.formatted(date: .abbreviated, time: .shortened))
									.font(.system(size: 16, weight: .medium, design: .rounded))
									.foregroundStyle(.secondary)
							}
						}
					}
				}
			}
			.scrollDismissesKeyboard(.immediately)
			.navigationTitle(isEditing ? "Edit Event" : "Add Event")
			.navigationBarTitleDisplayMode(.inline)
			.alert("Deletion Failed", isPresented: $showErrorAlert) {
				Button("OK", role: .cancel) { }
			} message: {
				 Text("The event could not be deleted. Please try again. \n\nDetails: \(errorMessage)")
			}
			.toolbar { toolbarContent }
			.onAppear {
				focusedField = true
				load()
			}
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
		if let event = existingEvent {
			ToolbarItem(placement: .bottomBar) {
				Button("Delete Event", role: .destructive) {
					Task {
						do {
							try ekManager.store.remove(event, span: .thisEvent, commit: true)
							await ekManager.refresh()
							WidgetCenter.shared.reloadAllTimelines()
						} catch {
							await MainActor.run {
								errorMessage = error.localizedDescription
								showErrorAlert = true
							}
						}
					}
				}
				.tint(.red)
			}
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
