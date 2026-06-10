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
	@FocusState private var focusedField: Bool

	var ekManager: EventKitManager
	var existingReminder: EKReminder?
	var mode: EventViewMode = .add
	var isEditing: Bool { mode == .edit }
	
	@State private var showErrorAlert: Bool = false
	@State private var errorMessage: String = ""
	
	@State private var title: String = ""
	@State private var hasDueDate: Bool = false
	@State private var dueDate: Date = Date()
	@State private var notes: String = ""
	@State private var saved: Bool = false
	@State private var closed: Bool = false
	
    var body: some View {
		NavigationStack {
			VStack {
				Form {
					Section {
						TextField("Title", text: $title, axis: .vertical)
							.font(.system(size: 20, weight: .semibold, design: .rounded))
							.lineLimit(3)
							.focused($focusedField)
					}
					if isEditing, let existing = existingReminder {
						Section {
							Toggle(isOn: $hasDueDate) {
								Label(hasDueDate ? "Due Date" : "No Due Date", systemImage: "calendar.badge.clock")
									.font(.system(size: 18, weight: .medium, design: .rounded))
							}
							if hasDueDate {
								DatePicker(selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) {
									Label("Date & Time", systemImage: "clock")
										.font(.system(size: 18, weight: .medium, design: .rounded))
								}
							}
							
						}
						.disabled(existing.isCompleted)
						
						
					} else {
						Section {
							Toggle(isOn: $hasDueDate) {
								Label("Due Date", systemImage: "calendar.badge.clock")
									.font(.system(size: 18, weight: .medium, design: .rounded))
							}
							if hasDueDate {
								DatePicker(selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) {
									Label("Date & Time", systemImage: "clock")
										.font(.system(size: 18, weight: .medium, design: .rounded))
								}
							}
						}
					}
					
					Section {
						TextField("Notes", text: $notes, axis: .vertical)
							.font(.system(size: 18, weight: .medium, design: .rounded))
							.lineLimit(4...8)
					}
					Section {
						if let existing = existingReminder, let createDate = existing.creationDate, let modifyDate = existing.lastModifiedDate {
						HStack {
							Label(existing.isCompleted ? "Completed" : "Not Completed",
								  systemImage: existing.isCompleted ? "checkmark.circle.fill" : "circle"
							)
							.font(.system(size: 18, weight: .medium, design: .rounded))
							.foregroundStyle(existing.isCompleted ? .green : .secondary)
							
							if let completionDate = existing.completionDate {
								Spacer()
								Text(completionDate.formatted(date: .abbreviated, time: .shortened))
									.font(.system(size: 16, weight: .medium, design: .rounded))
									.foregroundStyle(.secondary)
							}
						}
						
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
			}
			.scrollDismissesKeyboard(.immediately)
			.navigationTitle(isEditing ? "Details" : "New Reminder")
			.navigationBarTitleDisplayMode(.inline)
			.alert("Deletion Failed", isPresented: $showErrorAlert) {
				Button("OK", role: .cancel) { }
			} message: {
				 Text("The reminder could not be deleted. Please try again. \n\nDetails: \(errorMessage)")
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
			Button(role: .cancel) {
				closed = true
				dismiss()
			}
			.sensoryFeedback(.stop, trigger: closed)
		}
		if let reminder = existingReminder {
			ToolbarItem(placement: .bottomBar) {
				Button("Delete Reminder", role: .destructive) {
					Task {
						do {
							try ekManager.store.remove(reminder, commit: true)
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
