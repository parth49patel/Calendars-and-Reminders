	//
	//  ReminderRow.swift
	//  CalRem
	//
	//  Created by Parth Patel on 2026-05-05.
	//

import SwiftUI
import EventKit
import WidgetKit

struct ReminderRow: View {
	
	let reminder: EKReminder
	let ekManager: EventKitManager
	
	@State private var isCompleted: Bool
	@State private var isExpanded: Bool
	
	private static func shouldAutoExpand(_ reminder: EKReminder) -> Bool {
		guard let dueComponents = reminder.dueDateComponents,
			  let dueDate = Calendar.current.date(from: dueComponents) else {
			return true
		}
		return Calendar.current.isDateInToday(dueDate)
	}
	
	private var isOverdue: Bool {
		if !isCompleted,
		   let dueComponents = reminder.dueDateComponents, let dueDate = Calendar.current.date(from: dueComponents) {
			let calendar = Calendar.current
			return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: Date())
		}
		return false
	}
	
	init(reminder: EKReminder, ekManager: EventKitManager) {
		self.reminder = reminder
		self.ekManager = ekManager
		self._isCompleted = State(initialValue: reminder.isCompleted)
		self._isExpanded = State(initialValue: Self.shouldAutoExpand(reminder))
	}
	
	var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: 12) {
			HStack(alignment: .top) {
				Button {
					withAnimation(.snappy) {
						isCompleted.toggle()
					}
					Task {
						ekManager.toggleReminder(reminder, isCompleted: isCompleted)
						await ekManager.refresh()
						WidgetCenter.shared.reloadAllTimelines()
					}
				} label: {
					Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
						.font(.system(size: 20, weight: .medium))
						.foregroundStyle(isCompleted ? .green : .secondary)
						.contentTransition(.symbolEffect(.replace))
						.frame(width: 44, height: 44)
				}
				.buttonStyle(.plain)
				.sensoryFeedback(isCompleted ? .selection : .success, trigger: isCompleted)
			}
			
			VStack(alignment: .leading, spacing: 4) {
				Text(reminder.title)
					.font(.system(size: (isExpanded || isOverdue) ? 20 : 16, design: .rounded))
					.foregroundStyle(isCompleted ? .secondary : .primary)
					.bold(isExpanded || isOverdue)
					.strikethrough(isCompleted, color: .secondary)
					.lineLimit(isExpanded ? 2 : 1)
				
				if isCompleted {
					if let completionDate = reminder.completionDate {
						Text(completionDate.formatted(date: .abbreviated, time: .shortened))
							.font(.system(size: isExpanded ? 14 : 12, weight: .medium, design: .rounded))
							.foregroundStyle(.green)
							.padding(.horizontal, 8)
							.padding(.vertical, 2)
							.background(.green.opacity(0.15), in: Capsule())
					} else {
						Text("Completed")
							.font(.system(size: isExpanded ? 14 : 12, weight: .medium, design: .rounded))
							.foregroundStyle(.green)
							.padding(.horizontal, 8)
							.padding(.vertical, 2)
							.background(.green.opacity(0.15), in: Capsule())
					}
				} else if let dueComponents = reminder.dueDateComponents,
						  let dueDate = Calendar.current.date(from: dueComponents) {
					Text(dueDate.formatted(date: .omitted, time: .shortened))
						.font(.system(size: isExpanded ? 14 : 12, weight: .medium, design: .rounded))
						.foregroundStyle(dueDate < Date.now ? .red : .secondary)
						.padding(.horizontal, 8)
						.padding(.vertical, 2)
						.background(dueDate < Date.now ? .red.opacity(0.15) : .secondary.opacity(0.15), in: Capsule())
				} else {
					Text("No Due Date")
						.font(.system(size: isExpanded ? 14 : 12, weight: .medium, design: .rounded))
						.foregroundStyle(.secondary)
						.padding(.horizontal, 8)
						.padding(.vertical, 2)
						.background(.secondary.opacity(0.15), in: Capsule())
				}
				if isExpanded, let note = reminder.notes, !note.isEmpty {
					Text(note)
						.font(.system(size: 13, design: .rounded))
						.foregroundStyle(.secondary)
						.lineLimit(3)
						.padding(.top, 2)
				}
			}
			
			Spacer()
			
			if isOverdue && !isCompleted {
				Text("Overdue")
					.font(.system(size: 11, weight: .semibold, design: .rounded))
					.foregroundStyle(.red.opacity(0.9))
					.padding(.horizontal, 7)
					.padding(.vertical, 3)
					.background(.red.opacity(0.15), in: Capsule())
			}
		}
	}
}

#Preview("Today") {
	ReminderRow(reminder: MockData.sampleReminder, ekManager: EventKitManager())
}

#Preview("Tomorrow") {
	ReminderRow(reminder: MockData.sampleReminderUpcoming, ekManager: EventKitManager())
}

/*
 var body: some View {
	 HStack(alignment: .top, spacing: 12) {
		 HStack(alignment: .top) {
				 Button {
					 withAnimation(.snappy) {
						 isCompleted.toggle()
						 }
					 Task {
						 ekManager.toggleReminder(reminder, isCompleted: isCompleted)
						 await ekManager.refresh()
						 WidgetCenter.shared.reloadAllTimelines()
					 }
				 } label: {
					 Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
						 .font(.title2)
						 .foregroundStyle(isCompleted ? .green : .gray)
						 .frame(width: 44, height: 44)
				 }
				 .buttonStyle(.plain)
			 }
		 
		 VStack(alignment: .leading, spacing: 4) {
			 Text(reminder.title)
				 .font(.system(size: (isExpanded || isOverdue) ? 20 : 16, design: .default))
				 .foregroundStyle(.primary)
				 .bold(isExpanded || isOverdue)
				 .strikethrough(isCompleted, color: .secondary)

			 if isCompleted {
				 if let completionDate = reminder.completionDate {
					 Text("Completed: \(completionDate.formatted(date: .abbreviated, time: .shortened))")
						 .foregroundStyle(.secondary)
				 } else {
					 Text("Completed")
						 .foregroundStyle(.secondary)
				 }
			 } else {
				 if let dueComponents = reminder.dueDateComponents,
					let dueDate = Calendar.current.date(from: dueComponents) {
					 Text("Due: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
						 .foregroundStyle(dueDate < Date.now ? .red : .secondary)
				 } else {
					 Text("No due date")
						 .foregroundStyle(.secondary)
				 }
			 }
			 
			 if isExpanded {
				 if let note = reminder.notes, note.isEmpty == false {
					 Text(note)
						 .foregroundStyle(.secondary)
				 }
			 }
		 }
		 .font(isExpanded ? .subheadline : .caption)
	 }
 }
 */
