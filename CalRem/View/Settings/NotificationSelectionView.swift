//
//  NotificationSelectionView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-05-19.
//

import SwiftUI

struct NotificationSelectionView: View {
		
    var body: some View {
		Form {
			Section {
				
			} header: {
				Text("Daily Brief")
			} footer: {
				Text("Notifications are scheduled each morning with your latest data.")
			}
			.fontDesign(.rounded)
		}
		.navigationTitle("Notifications")
		.navigationBarTitleDisplayMode(.inline)
		
    }
}

#Preview {
	NavigationStack {
		NotificationSelectionView()
	}
}
