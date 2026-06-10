//
//  CalRemApp.swift
//  CalRem
//
//  Created by Parth Patel on 2026-04-27.
//

import SwiftUI
import SwiftData
import EventKit

@main
struct CalRemApp: App {
	
	@AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
	@State private var ekManager = EventKitManager()
   
	var body: some Scene {
        WindowGroup {
			if onboardingCompleted {
				ContentView()
					.environment(ekManager)
					.task {
						await ekManager.requestPermission()
					}
			} else {
				OnboardingView()
					.environment(ekManager)
			}
		}
    }
}
