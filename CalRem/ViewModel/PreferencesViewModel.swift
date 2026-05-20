//
//  PreferencesViewModel.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-05.
//

import Foundation

@Observable
class PreferencesViewModel {
	
	static let shared = PreferencesViewModel()
	private let defaults = UserDefaults(suiteName: "group.com.pp.CalRem") ?? .standard
	
	init() {
		let stored = UserDefaults.standard.stringArray(forKey: "selectedCalendarIdentifiers")
		self.selectedCalendarIdentifiers = Set(stored ?? [])
		
		let storedLimit = UserDefaults.standard.integer(forKey: "upcomingDaysLimit")
		self.upcomingDaysLimit = storedLimit == 0 ? 7 : storedLimit
	}
	
	var selectedCalendarIdentifiers: Set<String> {
		didSet {
			let array = Array(selectedCalendarIdentifiers)
			UserDefaults.standard.set(array, forKey: "selectedCalendarIdentifiers")
		}
	}
	
	var upcomingDaysLimit: Int {
		didSet {
			UserDefaults.standard.set(upcomingDaysLimit, forKey: "upcomingDaysLimit")
		}
	}
	
	var hasRunFirstLaunchSetup: Bool {
		get { UserDefaults.standard.bool(forKey: "hasRunFirstLaunchSetup") }
		set { UserDefaults.standard.set(newValue, forKey: "hasRunFirstLaunchSetup") }
	}
}
