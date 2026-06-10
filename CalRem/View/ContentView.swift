//
//  ContentView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-04-27.
//

import SwiftUI
import SwiftData
import EventKit
import WidgetKit

struct ContentView: View {
	
	@Environment(EventKitManager.self) var ekManager
	@Environment(\.scenePhase) private var scenePhase
	
	var body: some View {
		TabView {
			Tab("Events", systemImage: "calendar.day.timeline.trailing") {
				ListView()
			}
			Tab("Settings", systemImage: "gearshape") {
				SettingsTab()
			}
		}
		.tabViewStyle(.sidebarAdaptable)
		.task {
			WidgetCenter.shared.reloadAllTimelines()
			await ekManager.refresh()
		}
		.onChange(of: scenePhase) { oldPhase, newPhase in
			if newPhase == .active {
				Task {
					await ekManager.refresh()
					WidgetCenter.shared.reloadAllTimelines()
				}
			}
		}
	}
}

#Preview {
    ContentView()
		.environment(EventKitManager())
}
