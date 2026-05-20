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
	
	@Bindable var ekManager: EventKitManager
	@State private var eventType: EventType?
	@State private var showErrorAlert: Bool = false
	@State private var errorMessage: String = ""
	
	@State private var showEventView: Bool = false
	@State private var selectedEvent: EKEvent?
	@State private var showReminderView: Bool = false
	@State private var selectedReminder: EKReminder?
		
	var body: some View {
		NavigationStack {
			Group {
				if ekManager.unifiedItems.isEmpty {
					ContentUnavailableView("Nothing Scheduled", systemImage: "tray", description: Text(""))
				} else {
					itemList
				}
			}
			.navigationTitle("Upcoming")
			.task {
				if !ekManager.permissionGranted {
					await ekManager.requestPermission()
					WidgetCenter.shared.reloadAllTimelines()
				}
				await ekManager.refresh()
			}
			.sheet(isPresented: $showReminderView, onDismiss: { selectedReminder = nil }) {
				ReminderView(ekManager: ekManager, existingReminder: selectedReminder, mode: selectedReminder == nil ? .add : .edit)
			}
			.sheet(isPresented: $showEventView, onDismiss: { selectedEvent = nil }) {
				EventView(ekManager: ekManager, existingEvent: selectedEvent, mode: selectedEvent == nil ? .add : .edit)
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
										.onTapGesture {
											selectedEvent = event
											showEventView = true
										}
									
								case .reminder(let reminder):
									ReminderRow(reminder: reminder, ekManager: ekManager)
										.onTapGesture {
											selectedReminder = reminder
											showReminderView = true
										}
								}
						}
						.listRowSeparator(.visible)
						.listRowInsets(EdgeInsets(top: 8, leading: 32, bottom: 8, trailing: 32))

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
						   .font(.system(size: 14, weight: .bold, design: .rounded))
						   .foregroundStyle(.primary)
						   .textCase(nil)
						Spacer()
					   Text("\(group.items.count)")
						   .font(.system(size: 14, weight: .semibold, design: .rounded))
						   .foregroundStyle(.primary)
		
				   }
				   .padding(.horizontal, 16)
				   .padding(.top, 12)
				   .padding(.bottom, 4)
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
					showEventView = true
				} label: {
					Label("New Event", systemImage: "calendar")
				}
				
				Button {
					eventType = .reminder
					showReminderView = true
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
	ListView(ekManager: EventKitManager())
}
