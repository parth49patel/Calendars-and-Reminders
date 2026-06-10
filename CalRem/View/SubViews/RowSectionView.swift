//
//  RowSectionView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-06-04.
//

import SwiftUI

struct RowSectionView: View {
	
	@Environment(\.colorScheme) private var colorScheme
	let icon: String
	let color: Color
	let title: String
	let subTitle: String
	
    var body: some View {
		HStack(spacing: 16) {
			Circle()
				.fill(colorScheme == .light ? .thinMaterial : .thickMaterial)
				.frame(width: 50)
				.overlay {
					Image(systemName: icon)
						.font(.system(size: 25))
						.foregroundStyle(color)
				}
			
			VStack(alignment: .leading, spacing: 6) {
				Text(title)
					.font(.system(size: 24, weight: .semibold, design: .rounded))
					.foregroundStyle(.accent)
				Text(subTitle)
					.font(.system(size: 20, weight: .medium, design: .rounded))
					.foregroundStyle(.accent)
			}
		}
    }
}

#Preview {
	ZStack {
		Color.blue.opacity(0.5)
			.ignoresSafeArea()
		RowSectionView(icon: "icloud.fill", color: .blue, title: "iCloud Sync", subTitle: "Sync your reminders and events with Apple iCloud")
	}
}
