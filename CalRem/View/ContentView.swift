//
//  ContentView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-04-27.
//

import SwiftUI
import SwiftData
import EventKit

struct ContentView: View {

	@State private var ekManager = EventKitManager()
	@Environment(\.scenePhase) private var scenePhase
	
	var body: some View {
		TabView {
			Tab("Events", systemImage: "calendar.day.timeline.trailing") {
				ListView(ekManager: ekManager)
			}
			Tab("Settings", systemImage: "gearshape") {
				SettingsTab(ekManager: ekManager)
			}
		}
		.tabViewStyle(.sidebarAdaptable)
		.tabViewSidebarBottomBar {
			Image(systemName: "plus")
		}
		.task {
			await ekManager.refresh()
		}
//		.onChange(of: scenePhase) {
//			if scenePhase == .active {
//				Task {
//					await ekManager.refresh()
//				}
//			}
//		}
//		.onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
//			Task {
//				await ekManager.refresh()
//			}
//		}
	}
}

#Preview {
    ContentView()
}
