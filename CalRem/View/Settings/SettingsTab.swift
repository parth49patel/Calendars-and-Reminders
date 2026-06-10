//
//  ProfileView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-05.
//

import SwiftUI
import EventKit

struct SettingsTab: View {
	
	@Environment(EventKitManager.self) var ekManager
	@Environment(\.scenePhase) private var scenePhase
	
	var preferences = PreferencesViewModel.shared
	
    var body: some View {
		@Bindable var preferences = preferences
		NavigationStack {
			Form {
				Section("Calendars") {
					ForEach(ekManager.availableCalendars, id: \.calendarIdentifier) { calendar in
							LabeledContent {
								if preferences.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) {
									Image(systemName: "checkmark")
										.foregroundStyle(Color(cgColor: calendar.cgColor))
								}
							} label: {
								HStack {
									Image(systemName: "calendar")
										.foregroundStyle(Color(cgColor: calendar.cgColor))
									Text(calendar.title)
								}
							}
						.fontDesign(.rounded)
						.contentShape(Rectangle())
						.onTapGesture {
							ekManager.toggleCalendar(calendar.calendarIdentifier)
							Task {
								await ekManager.refresh()
							}
						}
					}
				}
				
				Section("Sync Options") {
					Picker("Fetch Events & Reminders For", selection: $preferences.upcomingDaysLimit) {
						Text("1 day").tag(1)
						Text("7 days").tag(7)
						Text("14 days").tag(14)
						Text("30 days").tag(30)
					}
					.fontDesign(.rounded)
					.onChange(of: preferences.upcomingDaysLimit) { oldValue, newValue in
						Task {
							await ekManager.refresh()
						}
					}
				}
				
				Section("Permissions") {
					PermissionRow(title: "Calendar", isGranted: ekManager.calendarGranted)
					PermissionRow(title: "Reminders", isGranted: ekManager.reminderGranted)
					
					if !ekManager.calendarGranted || !ekManager.reminderGranted {
						Button {
							if let url = URL(string: UIApplication.openSettingsURLString) {
								#if os(iOS)
								UIApplication.shared.open(url)
								#elseif os(macOS)
								NSWorkspace.shared.open(url)
								#endif
							}
						} label: {
							HStack {
								Text("Open Settings to Grant Access")
								Spacer()
								Image(systemName: "arrow.up.forward.app")
							}
						}
					}
				}
			}
			.navigationTitle("Settings")
			.onAppear {
				ekManager.fetchAvailableCalendars()
			}
			.onChange(of: scenePhase) { oldPhase, newPhase in
				if newPhase == .active {
					ekManager.checkCurrentPermissionStatus()
				}
			}
		}
    }
}

#Preview {
    SettingsTab()
		.environment(EventKitManager())
}

struct PermissionRow: View {
	let title: String
	let isGranted: Bool
	
	var body: some View {
		HStack {
			Text(title)
			Spacer()
			Text(isGranted ? "Granted" : "Denied")
				.foregroundStyle(isGranted ? .secondary : Color.red)
		}
		.fontDesign(.rounded)
	}
}
