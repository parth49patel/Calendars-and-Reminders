//
//  ListView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-05.
//

import SwiftUI
import EventKit
import WidgetKit

struct ListView: View {
	
	@Environment(EventKitManager.self) var ekManager
	@Environment(\.scenePhase) private var scenePhase
	@Namespace private var present
	
	@State private var eventType: EventType?
	@State private var showErrorAlert: Bool = false
	@State private var errorMessage: String = ""
	
	@State private var showAddEvent: Bool = false
	@State private var showAddReminder: Bool = false
	@State private var eventToEdit: EKEvent?
	@State private var reminderToEdit: EKReminder?
	
	@State private var selectedDate: Date = .now
	var preferences = PreferencesViewModel.shared
	
	var body: some View {
		@Bindable var ekManager = ekManager
		NavigationStack {
			Group {
				if ekManager.isLoading {
					Color.clear
				}
				else if !ekManager.calendarGranted && !ekManager.reminderGranted {
					ContentUnavailableView("Access Required", systemImage: "lock.fill", description: Text("Calendar and Reminder access needed."))
				}
				else if ekManager.unifiedItems.isEmpty {
					ContentUnavailableView("Nothing Scheduled", systemImage: "tray", description: Text("You have nothing scheduled for next \(preferences.upcomingDaysLimit) days."))
				}
				else {
					itemList
				}
			}
			.navigationTitle("Schedule")
			.sheet(isPresented: $showAddReminder) {
				ReminderView(ekManager: ekManager, existingReminder: nil, mode: .add)
			}
			.sheet(item: $reminderToEdit) { reminder in
				ReminderView(ekManager: ekManager, existingReminder: reminder, mode: .edit)
					.navigationTransition(.zoom(sourceID: "reminder", in: present))
			}
			.sheet(isPresented: $showAddEvent) {
				EventView(ekManager: ekManager, existingEvent: nil, mode: .add)
			}
			.sheet(item: $eventToEdit) { event in
				EventView(ekManager: ekManager, existingEvent: event, mode: .edit)
					.navigationTransition(.zoom(sourceID: "event", in: present))
			}
			.toolbar { toolbarContent }
			.alert("Deletion Failed", isPresented: $showErrorAlert) {
				Button("OK", role: .cancel) { }
			} message: {
				 Text("Could not delete this item. Please try again. \n\nDetails: \(errorMessage)")
			}
		}
	}
	
	// MARK: - List
	private var itemList: some View {
		List {
			ForEach(ekManager.groupedByDate, id: \.date) { group in
				Section {
					ForEach(group.items) { item in
						Group {
							switch item {
								case .event(let event):
									EventRow(event: event, ekManager: ekManager)
										.contentShape(Rectangle())
										.onTapGesture {
											eventToEdit = event
										}
										.sensoryFeedback(.selection, trigger: eventToEdit)
									
								case .reminder(let reminder):
									ReminderRow(reminder: reminder, ekManager: ekManager)
										.contentShape(Rectangle())
										.onTapGesture {
											reminderToEdit = reminder
										}
										.sensoryFeedback(.selection, trigger: reminderToEdit)
								}
						}
						.listRowSeparator(.hidden)
						.listRowInsets(EdgeInsets(top: 4, leading: 32, bottom: 16, trailing: 32))

							// MARK: SwipeActions
						.swipeActions(edge: .trailing, allowsFullSwipe: false) {
							Button(role: .destructive) {
								Task {
									do {
										switch item {
											case .event(let event):
												try ekManager.store.remove(event, span: .thisEvent, commit: true)
											case .reminder(let reminder):
												try ekManager.store.remove(reminder, commit: true)
										}
										await ekManager.refresh()
										WidgetCenter.shared.reloadAllTimelines()
									} catch {
										await MainActor.run {
											errorMessage = error.localizedDescription
											showErrorAlert = true
										}
									}
								}
							} label: {
								Label("Delete", systemImage: "trash")
							}
							
							Button {
								switch item {
									case .event:
										if let url = URL(string: "calshow:") {
											UIApplication.shared.open(url)
										}
									case .reminder(_):
										if let url = URL(string: "x-apple-reminderkit://") {
											UIApplication.shared.open(url)
										}
								}
							} label: {
								switch item {
									case .event:
										Label("Calendar", systemImage: "calendar")
											.tint(.red)
									case .reminder:
										Label("Reminder", systemImage: "list.bullet")
											.tint(.blue)
								}
							}
						}
					}
				} header: {
					HStack(alignment: .firstTextBaseline) {
					    Text(formatSectionDate(group.date))
								.textCase(nil)
						Spacer()
						Text("\(group.items.count)")
				   }
					.font(.system(size: 16, weight: .semibold, design: .rounded))
					.foregroundStyle(.secondary)
					.padding(.horizontal, 8)
				}
			}
		}
		.id(ekManager.refreshID)
		.scrollIndicators(.hidden)
		.listStyle(.plain)
	}
	
	// MARK: - Toolbar
	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			Menu {
				Button {
					eventType = .calendar
					showAddEvent = true
				} label: {
					Label("New Event", systemImage: "calendar")
				}
				
				Button {
					eventType = .reminder
					showAddReminder = true
				} label: {
					Label("New Reminder", systemImage: "checklist")
				}
			} label: {
				Image(systemName: "plus")
					.fontWeight(.semibold)
			}
		}
	}
	
	private func formatSectionDate(_ date: Date) -> String {
		let calendar = Calendar.current
		if calendar.isDateInToday(date) { return "Today" }
		if calendar.isDateInTomorrow(date) { return "Tomorrow" }
		let formatter = DateFormatter()
		formatter.dateFormat = "EEEE, MMM d"
		return formatter.string(from: date)
	}
}

#Preview {
	ListView()
		.environment(EventKitManager())
}
