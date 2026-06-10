# Calendar & Reminders - CalRem

**Know your day. Plan your week.**  
A native iOS app that unifies Apple Calendar and Reminders into one clean, scrollable view — with widgets and two-way sync.  

---

## Why I Built This

I use Apple Calendar and Reminders daily, but switching between the two apps to get a complete view of my day always felt inefficient.  
This project brings those experiences together and showcases how Apple’s frameworks can be combined in a cohesive SwiftUI application. It integrates **EventKit, WidgetKit, App Intents, and CloudKit** in a single codebase.  
The goal was to demonstrate proficiency in building and integrating features across Apple’s ecosystem using first-party APIs.  

## What CalRem Does

CalRem reads directly from your Apple Calendar and Reminders — no new data store, no account required. It surfaces your next 1, 7, 14, or 30 days in a unified list, sorted chronologically, with events and reminders sorted by date & time.

**Core features:**
- Unified list of Calendar events and Reminders for a configurable window (1 / 7 / 14 / 30 days)
- Add, edit, and delete events and reminders without leaving the app
- Two-way sync — changes in CalRem appear instantly in Apple Calendar and Reminders, and vice versa
- Configurable calendar selection — show only the calendars you care about
- 5 widget types across home screen and lock screen

## Screenshots

### List View
<img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/list.imageset/list.png" width="200"/>

---

### Onboarding
<p float="left">
  <img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/welcome.imageset/welcome.png" width="200"/>
  <img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/features.imageset/features.png" width="200"/>
  <img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/permission.imageset/permission.png" width="200"/>
  <img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/allset.imageset/allset.png" width="200"/>
</p>

---

### Widgets

<p float="left">
  <img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/widget-1.imageset/widget-1.png" width="200"/>
  <img src="https://github.com/parth49patel/Calendars-and-Reminders/blob/main/CalRem/Assets.xcassets/widget-2.imageset/widget-2.png" width="200"/>
</p>

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| State Management | `@Observable`, `@Bindable` |
| Calendar & Reminders | EventKit |
| Widgets | WidgetKit + AppIntents |
| Interactive Widgets | `AppIntent` + `ToggleReminderIntent` |
| Lock Screen Widgets | `accessoryRectangular` |
| Cross-Target Data | App Groups + shared `UserDefaults` suite |
| Mac Support | Mac Catalyst |

### Key Design Decisions

**`CalendarItem` enum**  
Rather than working with `EKEvent` and `EKReminder` separately throughout the UI, a single `CalendarItem` enum wraps both. This gives a unified `id`, `title`, `sortDate`, and lets every view switch over a single type.

```swift
enum CalendarItem: Identifiable {
    case event(EKEvent)
    case reminder(EKReminder)
    
    var sortDate: Date { ... }
    var title: String { ... }
}
```

**`@Observable` over `ObservableObject`**  
CalRem uses `@Observable` macro instead of `ObservableObject` + `@Published`. This eliminates unnecessary view re-renders — only views that read a specific property re-render when that property changes, rather than the entire view tree.

**Shared `EventKitDataService` for widgets**  
Widgets can't access the main app's `EventKitManager` instance directly. A shared stateless `EventKitDataService` struct handles all widget data fetching, reading preferences from the shared App Group `UserDefaults` suite to respect the user's calendar selection.

**`groupedByDate` with multi-day event expansion**  
A key architectural challenge was that `Dictionary(grouping:)` puts each item in exactly one bucket. Multi-day all-day events need to appear on every day they span. The solution was switching from `Dictionary(grouping:)` to a manual loop that appends the same `CalendarItem` reference to multiple date buckets.

---
## Onboarding

CalRem includes a 4-step custom onboarding flow built entirely in SwiftUI without any third-party library.

```
Step 1 — Welcome         Introduces the app with icon and tagline
Step 2 — Features        Shows what the app does before asking for anything
Step 3 — Permissions     Explains Calendar and Reminders access with context
Step 4 — All Set         Confirms access granted, or guides to Settings if denied
```

**Key decisions:**
- Permission request is on step 3, not step 1 — users understand the value before being asked
- A helper line reads *"You'll see two permission prompts"* before tapping Allow Access, so the sequential iOS system dialogs don't feel like a bug
- If the user denies permission, step 4 adapts — it shows a lock icon, explains access is required, and offers an "Open Settings" button rather than a dead end
- `@AppStorage("hasCompletedOnboarding")` persists completion state — onboarding never shows again after the first run
- The "Not Now" option is present on the permission step — Apple rejects apps that force permission before granting entry

---

## Widgets

CalRem ships 5 widget types across home screen and lock screen, built with WidgetKit and AppIntents.

### Home Screen Widgets

**Today's Timeline** — `UnifiedWidget`  
Shows a list of today's pending events and reminders. Supports `.systemMedium` and `.systemLarge`. Includes an interactive toggle button on reminders via `ToggleReminderIntent` — check off a reminder directly from the home screen without opening the app.

**Focus Widget** — `FocusWidget`  
Shows the single most relevant upcoming item — the next event or the highest priority reminder. Supports `.systemSmall`. Differentiates between reminder and calendar event using different color for each.

**Week Glance** — `WeekGlanceWidget`  
A 7-day bar chart showing event and reminder counts per day. Built with SwiftUI `Chart` from the Charts framework. Lets users see their week load at a glance without opening the app. Supports `.systemMedium` and `.systemLarge`.

### Lock Screen Widgets

**Accessory Rectangular** — `accessoryRectangular`  
Shows up to 3 upcoming items as a compact list on the lock screen. Designed for information density — title and time only, no decorative elements. Includes an interactive toggle button to check off reminders.

### Widget Architecture Notes

- All widgets share a single `EventKitDataService` that fetches from EventKit using the same calendar selection preferences as the main app
- `getSnapshot()` always returns mock data so the widget gallery preview is never empty
- `getTimeline()` uses a 15-minute refresh policy — `policy: .after(EventKitDataService.nextUpdate())`
- Calendar selection preferences are shared between the main app and widget extension via an **App Group** and a shared `UserDefaults` suite — without this the widget would show all calendars regardless of the user's selection

---
## Key Learnings

**EventKit is deeper than it looks**  
EKEvent and EKReminder have many optional fields that can crash your app silently — `event.title` is optional, `event.calendar` can be nil on corrupt data, `reminder.completionDate` can be nil even when `isCompleted` is true. Defensive unwrapping everywhere is not optional.

**Recurring events are a trap**  
Saving a recurring event without specifying the correct `EKSpan` applies changes to all future occurrences silently. A `confirmationDialog` asking "This event only / This and future events / All events" is essential — exactly what Apple Calendar does.

**Widgets and the main app can't share memory**  
The widget extension runs in a separate process. Any data the widget needs must go through a shared `UserDefaults` suite via App Groups. A common bug is writing preferences to `UserDefaults.standard` in the main app and wondering why the widget ignores the calendar filter.

**`@Observable` vs `ObservableObject`**  
The iOS 17 `@Observable` macro is strictly better for SwiftUI — it tracks property access at the call site rather than publishing all changes.

**`Dictionary(grouping:)` has a fundamental limitation for calendar data**  
It can only place each item in one bucket. Multi-day all-day events must appear on every day they span — this requires a manual loop, not `grouping:`. A June 19–21 event must appear in three separate date sections.

**WidgetKit `getSnapshot` is the widget gallery**  
`getSnapshot` is called when the user browses the widget picker on a real device. Returning an empty entry here means your widget looks blank in the gallery. Always return representative mock data from `getSnapshot`.

### Known Edge Cases
- Recurring events need a span selection dialog on edit (not yet implemented)
- Events created in a different timezone can appear on the wrong day near midnight
- Widget timeline does not refresh immediately when the user changes calendar selection in settings

### What Could Be Improved
- **Natural language input** — parse "call John tomorrow at 3pm" into a pre-filled event form using `NSDataDetector`
- **Free time finder** — scan the day's events and surface gaps ("You have 90 mins free at 2pm")
- **Travel time** — use `MKDirections` to estimate commute time to events with a location
- **watchOS companion** — today's list and a complication using the same `EventKitDataService`

---

## How to Run

### Requirements
- Xcode 26.5+
- iOS 26.0+ device or simulator
- macOS 26.5+ for Mac Catalyst build
- An Apple Developer account (free tier works for simulator; paid required for widgets on device)

### Setup

```bash
git clone https://github.com/parth49patel/Calendars-and-Reminders.git
cd CalRem
open CalRem.xcodeproj
```

### App Groups Configuration

To enable data sharing between the app, widgets, and App Intents:

- Open **Targets → Signing & Capabilities**
- Enable **App Groups** for both:
  - Main app target  
  - Widget extension target(s)

- Create or select a shared App Group identifier (e.g. `group.com.yourname.calrem`)
- Ensure the **same App Group** is used across all targets

> ⚠️ Without App Groups properly configured, the app and widgets will not sync data.
---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Author

Built by **Parth Patel** as a portfolio project to explore Apple's first-party frameworks in depth.

- [GitHub](https://github.com/parth49patel)
- [LinkedIn](https://linkedin.com/in/parth49)
- [Medium](https://medium.com/@4parth9)

---

> *Align is not on the App Store. This repository is a portfolio project demonstrating iOS development patterns across EventKit, WidgetKit, CloudKit, and Mac Catalyst.*
