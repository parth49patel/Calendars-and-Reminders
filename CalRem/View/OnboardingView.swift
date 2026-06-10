//
//  OnboardingView.swift
//  CalRem
//
//  Created by Parth Patel on 2026-06-04.
//

import SwiftUI

struct OnboardingView: View {
	
	@AppStorage("onboardingCompleted") private var onboardingCompleted = false
	@Environment(\.colorScheme) private var colorScheme
	@Environment(EventKitManager.self) var ekManager
	@State private var currentPage: Int = 0
	
    var body: some View {
		switch currentPage {
			case 0: welcomePage
			case 1: featuresPage
			case 2: permissionPage
			case 3: allSetPage
			default: welcomePage
		}
    }
	
	// MARK: - Welcome Page
	private var welcomePage: some View {
		ZStack {
			Color.orange.opacity(0.5)
				.ignoresSafeArea()
			
			VStack(spacing: 30) {
				Spacer()
				Circle()
					.fill(colorScheme == .light ? .thinMaterial : .thickMaterial)
					.frame(width: 150)
					.overlay {
						Image(systemName: "calendar.day.timeline.trailing")
							.font(.system(size: 75))
							.foregroundStyle(.orange)
					}
				
				Text("Welcome to Align")
					.font(.system(size: 24, weight: .semibold, design: .rounded))
					.foregroundStyle(.accent)
				
				Text("All your events and reminder in one place.")
					.font(.system(size: 20, weight: .medium, design: .rounded))
					.foregroundStyle(.accent)
				
				Spacer()
				Button {
					withAnimation {
						currentPage = 1
					}
				} label: {
					Text("Get Started")
						.font(.system(size: 20, weight: .semibold, design: .rounded))
						.foregroundStyle(.accent)
						.padding()
				}
				.buttonSizing(.flexible)
				.buttonStyle(.glass)
				.padding(.horizontal)
			}
			.multilineTextAlignment(.center)
			.padding(.horizontal)
		}
	}
	
	// MARK: - Features page
	private var featuresPage: some View {
		ZStack {
			Color.cyan.opacity(0.5)
				.ignoresSafeArea()
			
			VStack(alignment: .leading, spacing: 30) {
				Spacer()
				
				RowSectionView(icon: "icloud.fill", color: .blue, title: "Sync", subTitle: "Seamlessly sync with Apple Calendar and Reminders app.")
				
				RowSectionView(icon: "widget.small.badge.plus", color: .indigo, title: "Widgets", subTitle: "Glanceable schedule from your home and lock screen.")
				
				Spacer()
				
				Button {
					withAnimation {
						currentPage = 2
					}
				} label: {
					Text("Continue")
						.font(.system(size: 20, weight: .semibold, design: .rounded))
						.foregroundStyle(.accent)
						.padding()
				}
				.buttonSizing(.flexible)
				.buttonStyle(.glass)
				.padding(.horizontal)
			}
			.padding(.horizontal)
		}
	}
	
	// MARK: - Permission Page
	private var permissionPage: some View {
		ZStack {
			Color.blue.opacity(0.5)
				.ignoresSafeArea()
			
			VStack(alignment: .leading, spacing: 30) {
				Spacer()
				
				RowSectionView(icon: "calendar", color: .red, title: "Calendar", subTitle: "Align needs access to Apple Calendar to sync events.")
				
				RowSectionView(icon: "checklist", color: .purple, title: "Reminders", subTitle: "Align needs access to Apple Reminders to sync reminders.")
				
				Spacer()
				
				Text("You'll see two permission prompts once you tap Allow Access.")
					.font(.system(size: 16))
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 32)
				Button {
					Task {
						await ekManager.requestPermission()
						withAnimation {
							currentPage = 3
						}
					}
				} label: {
					Text("Allow Access")
						.font(.system(size: 20, weight: .semibold, design: .rounded))
						.foregroundStyle(.accent)
						.padding()
				}
				.buttonSizing(.flexible)
				.buttonStyle(.glass)
				.padding(.horizontal)
			}
			.padding(.horizontal)
		}
	}
	
	// MARK: - All Set Page
	private var allSetPage: some View {
		ZStack {
			Color(ekManager.permissionGranted ? .green : .gray).opacity(0.5)
				.ignoresSafeArea()
			
				VStack(spacing: 30) {
					Spacer()
					Circle()
						.fill(colorScheme == .light ? .thinMaterial : .thickMaterial)
						.frame(width: 150)
						.overlay {
							Image(systemName: ekManager.permissionGranted ? "checkmark" : "lock.fill")
								.font(.system(size: 75))
								.foregroundStyle(ekManager .permissionGranted ? .green : .gray)
						}
					
					Text(ekManager.permissionGranted ? "Your're all set" : "Access Denied")
						.font(.system(size: 24, weight: .semibold, design: .rounded))
						.foregroundStyle(.accent)
					
					Text(ekManager.permissionGranted ? "All your events and reminder in one place." : "You can enable access in Settings. You will not be able to view/add any events or reminders.")
						.font(.system(size: 20, weight: .semibold, design: .rounded))
						.foregroundStyle(.accent)
					
					Spacer()
					Button {
						withAnimation {
							onboardingCompleted = true
						}
					} label: {
						Text("Start Using Align")
							.font(.system(size: 20, weight: .semibold, design: .rounded))
							.foregroundStyle(.accent)
							.padding()
					}
					.buttonSizing(.flexible)
					.buttonStyle(.glass)
					.padding(.horizontal)
				}
				.multilineTextAlignment(.center)
				.padding(.horizontal)
		}
	}
}

#Preview {
    OnboardingView()
		.environment(EventKitManager())
}
