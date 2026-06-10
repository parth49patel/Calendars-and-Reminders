//
//  CalRemWidgetBundle.swift
//  CalRemWidget
//
//  Created by Parth Patel on 2026-05-11.
//

import WidgetKit
import SwiftUI

@main
struct CalRemWidgetBundle: WidgetBundle {
    var body: some Widget {
		UnifiedWidget()
		DayProgressWidget()
		WeekGlanceWidget()
		FocusWidget()
    }
}
