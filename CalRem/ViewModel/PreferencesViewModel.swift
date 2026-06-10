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
	private let defaults = UserDefaults(suiteName: "") ?? .standard
	
	init() {
		let stored = defaults.stringArray(forKey: "selectedCalendarIdentifiers")
		self.selectedCalendarIdentifiers = Set(stored ?? [])
		
		let storedLimit = defaults.integer(forKey: "upcomingDaysLimit")
		self.upcomingDaysLimit = storedLimit == 0 ? 7 : storedLimit
	}
	
	var selectedCalendarIdentifiers: Set<String> {
		didSet {
			let array = Array(selectedCalendarIdentifiers)
			defaults.set(array, forKey: "selectedCalendarIdentifiers")
		}
	}
	
	var upcomingDaysLimit: Int {
		didSet {
			defaults.set(upcomingDaysLimit, forKey: "upcomingDaysLimit")
		}
	}
}
