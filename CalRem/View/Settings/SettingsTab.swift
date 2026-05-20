//
//  ProfileView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-05.
//

import SwiftUI
import EventKit

struct SettingsTab: View {
	
	var ekManager = EventKitManager()
	var preferences = PreferencesViewModel.shared
	
    var body: some View {
		NavigationStack {
			Form {
				Section("Calendars") {
					ForEach(ekManager.availableCalendars, id: \.calendarIdentifier) { calendar in
						HStack {
							Circle()
								.fill(Color(cgColor: calendar.cgColor))
								.frame(width: 12, height: 12)
							Text(calendar.title)
							Spacer()
							
							if preferences.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) {
								Image(systemName: "checkmark")
									.foregroundStyle(.blue)
							}
						}
						.contentShape(Rectangle())
						.onTapGesture {
							ekManager.toggleCalendar(calendar.calendarIdentifier)
							Task {
								await ekManager.refresh()
							}
						}
					}
				}
				
				Section {
					NavigationLink(destination: NotificationSelectionView()) {
						Text("Notifications")
							.bold()
							.foregroundStyle(.accent)
					}
				}
			}
			.navigationTitle("Settings")
			.onAppear {
				ekManager.fetchAvailableCalendars()
			}
		}
    }
}

#Preview {
    SettingsTab()
}
