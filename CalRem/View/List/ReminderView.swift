//
//  ReminderView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-11.
//

import SwiftUI
import EventKit
import WidgetKit

struct ReminderView: View {
	
	@State private var reminder: EKReminder?
	@Environment(\.dismiss) private var dismiss
	
	var ekManager: EventKitManager
	var existingReminder: EKReminder?
	var mode: EventViewMode = .add
	var isEditing: Bool { mode == .edit }
	
	@State private var title: String = ""
	@State private var hasDueDate: Bool = false
	@State private var dueDate: Date = Date()
	@State private var notes: String = ""
	@State private var saved: Bool = false
	@State private var closed: Bool = false
	
    var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Title", text: $title)
						.bold()
				}
				
				Section {
					Toggle("Due Date", isOn: $hasDueDate)
						.bold()
					if hasDueDate {
						DatePicker("Date & Time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
					}
				}
				
				Section {
					TextField("Notes", text: $notes, axis: .vertical)
						.lineLimit(4...8)
				}
			}
			.navigationTitle(isEditing ? "Details" : "New Reminder")
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
			Button(role: .cancel) {
				closed = true
				dismiss()
			}
			.sensoryFeedback(.stop, trigger: closed)
		}
	}
	
	private func load() {
		guard let reminder = existingReminder else { return }
		title = reminder.title ?? ""
		hasDueDate = reminder.dueDateComponents != nil
		dueDate = reminder.dueDateComponents?.date ?? Date()
		notes = reminder.notes ?? ""
	}
	
	private func save () {
		let reminder = existingReminder ?? ekManager.store.defaultCalendarForNewReminders().flatMap { _ in
			EKReminder(eventStore: ekManager.store)
		} ?? EKReminder(eventStore: ekManager.store)
		reminder.title = title.trimmingCharacters(in: .whitespaces)
		reminder.notes = notes.isEmpty ? nil : notes
		if hasDueDate {
			reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
		} else {
			reminder.dueDateComponents = nil
		}
		
		if existingReminder == nil {
			reminder.calendar = ekManager.store.defaultCalendarForNewReminders()
		}
		do {
			try ekManager.store.save(reminder, commit: true)
			Task { await ekManager.refresh() }
			WidgetCenter.shared.reloadAllTimelines()
			dismiss()
		} catch {
			print("Cannot save reminder: \(error)")
		}
	}
}

#Preview {
	ReminderView(ekManager: EventKitManager())
}
