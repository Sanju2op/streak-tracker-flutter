# ARCHITECTURE.md

> Single source of truth for all technical decisions. Do not debate these in sessions — implement them.

---

## App Summary

A free, personal habit/streak tracker — a free Android-first alternative to "Days Since". Users create named streaks with a start date/time, watch them count up in real-time, reset them with a note, and review history via a calendar and stats. All features are free, no paid plans, no locks.

**Target platforms:** Android (primary), Web (secondary — testing + alternative usage), iOS (future, personal use)
**Testing:** Android APK on real device + Chrome browser on Windows 11
**Out of scope (v1):** Cloud sync, social sharing, paid tiers.

**UI Reference:** All design reference images are in `UI Images/` at the repo root. AI agents MUST open the relevant image before implementing any screen or component. The images take priority over any written description.

---

## Tech Stack — Locked In

| Layer               | Choice                                     | Why                                                              |
| ------------------- | ------------------------------------------ | ---------------------------------------------------------------- |
| Framework           | **Flutter stable channel**                 | Cross-platform, best Android + Web from one codebase             |
| Language            | **Dart (null-safe)**                       | Flutter's native language, strong typing enforced everywhere     |
| Flutter Version     | **Latest stable (3.38.4+)**               | Stable channel only; `pubspec.lock` enforces the minimum SDK     |
| State               | **flutter_riverpod ^2.5.x**               | Best-known Flutter state library for AI agents                   |
| Navigation          | **go_router ^14.x**                       | Shell routes for tabs, deep linking, widely understood           |
| Database (native)   | **sqflite ^2.3.x**                        | Most stable Flutter SQLite, Android + iOS                        |
| Database (web)      | **shared_preferences ^2.x**               | Key-value JSON storage for Flutter Web                           |
| Charts              | **fl_chart ^0.68.x**                      | Stable, well-known, works on Android + Web, no FFI               |
| Date Formatting     | **intl ^0.19.x**                          | Official Dart i18n/date formatting                               |
| Haptics             | **HapticFeedback** (flutter/services)      | Built-in Flutter, auto no-op on web                              |
| Calendar            | **table_calendar ^3.1.x**                | Most popular Flutter calendar, actively maintained               |
| Notifications       | **flutter_local_notifications ^17.x**     | Local-only reminders, no server needed                           |
| Permissions         | **permission_handler ^11.x**              | Android 13+ notification permission request                      |
| Android Widgets     | **home_widget ^0.6.x**                    | Flutter-native Android home/lock screen widget bridge            |
| UUID                | **uuid ^4.x**                             | Stable UUID generation                                           |
| Icons               | **Material Icons** (Flutter built-in)      | Covers all icons in the UI screens                               |
| Build (Android)     | **flutter build apk / appbundle**          | Direct CLI, no third-party CI needed                             |
| Build (Web)         | **flutter build web --release**           | Conservative static PWA build for broad hosting compatibility   |

> **Rule:** Do not add packages not in this table without updating this file first.

### Packages to avoid
- `get` / `GetX` — conflicts with Riverpod
- `bloc` / `flutter_bloc` — unnecessary complexity for this scale
- `drift` ORM — raw SQL with sqflite is cleaner for this app
- `hive` — redundant given sqflite + shared_preferences split
- Any FFI-dependent package — breaks Flutter Web builds

---

## No Cloud Database Required

The app is 100% offline. All data lives on device:
- Android/iOS → SQLite via `sqflite`
- Web → JSON in browser storage via `shared_preferences`

Cloud sync can be added later as an optional feature (Firebase, Supabase) but is **not planned for v1**.

---

## Cross-Platform Data Storage — Adapter Pattern

`sqflite` does not run on Flutter Web. Use a **single abstract interface** that both platforms implement.

### Interface — `lib/db/db_adapter.dart`

```dart
abstract class DbAdapter {
  Future<void> init();

  // Counters
  Future<List<Counter>> getCounters();
  Future<Counter?> getCounter(String id);
  Future<void> insertCounter(Counter counter);
  Future<void> updateCounter(Counter counter);
  Future<void> deleteCounter(String id);

  // Resets
  Future<List<Reset>> getResets(String counterId);
  Future<void> insertReset(Reset reset);

  // Goals
  Future<List<Goal>> getGoals(String counterId);
  Future<void> insertGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> deleteGoal(String id);
}
```

### Platform routing — `lib/db/db.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sqflite_adapter.dart';
import 'web_adapter.dart';

DbAdapter createAdapter() => kIsWeb ? WebAdapter() : SqfliteAdapter();
```

Exposed as a Riverpod provider:
```dart
// lib/providers/db_provider.dart
final dbAdapterProvider = Provider<DbAdapter>((ref) => createAdapter());
```

### Native — `lib/db/sqflite_adapter.dart`
- `sqflite` with raw SQL
- `openDatabase()` with `onCreate` running all schema SQL
- Enable foreign keys pragma on every connection open
- NEVER import `sqflite` outside this file

### Web — `lib/db/web_adapter.dart`
- `shared_preferences` as JSON-string storage
- Keys: `st_counters`, `st_resets`, `st_goals`
- All methods return `Future<T>` (async even though prefs is sync)
- Default to `[]` on missing/malformed keys

### Key rule
All Riverpod notifiers call `ref.read(dbAdapterProvider)`. Never import `SqfliteAdapter` or `WebAdapter` directly outside `lib/db/db.dart`.

---

## UI Design Language

> Images in `UI Images/` are the authoritative design source. Always open the relevant image first.

### Screen Background
- `Color(0xFFF2F2F7)` — light grey (iOS-style system background)

### Counter Cards — `UI Images/Counters_Tab.PNG`
- **2-column GridView**, each cell fills half the screen width
- Card: solid accent color background, `BorderRadius.circular(16)`
- **Translucent white circle** decoration — large, positioned towards bottom-right of the card, ~80–90% of card height in diameter, partially clipped by card bounds
- **Large number** (primary value) white, top-left inside card; **unit label** white smaller below it
- Below the card widget (not inside): **bold title** text, then muted grey subtitle
  - If never reset: "Started on D Mon" (e.g. "Started on 10 Jan")
  - If reset: "Reset on D Mon" (e.g. "Reset on 22 Feb")
- Card tap → navigate to counter detail screen

### Counter Detail — `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_1.PNG` + `..._2_scrolled.PNG`

**AppBar:**
- Back chevron + "Counters" text (blue) — left
- Counter title with accent-colored bullet dot — center (as shown in scrolled view AppBar)
- "Edit" text button (blue) — right

**Page content (scrollable):**

1. **Title block** — counter name large bold, "Started on [full date]" grey subtitle below, a 4px accent-colored vertical strip on the left edge

2. **Current Streak card** (white, rounded):
   - Row: "Current Streak" bold + "Started on [date]" grey subtitle | Share button (blue, outlined pill, share icon)
   - `TimeTabSelector`: Hours · Days · Weeks · Months · Years — segmented, active tab bold+outlined
   - 4-column elapsed breakdown: large bold number + grey label (e.g. "27 Years · 3 Months · 22 Days · 14 Hours")

3. **Reset Counter button** — full-width, accent color background, white text bold, `BorderRadius.circular(12)`

4. **Menu list card** (white, rounded, rows separated by dividers):
   - **All Resets** — stacked-squares icon (accent color), chevron right → navigates to All Resets screen
   - **Goals** — target/bullseye icon (accent color), chevron right → navigates to Goals screen
   - **Stats** — bar chart icon (accent color), chevron right → navigates to Stats screen
   - **Reminders** — bell icon (accent color), chevron right → navigates to Reminders screen
   - No locks, no premium stars. All rows fully functional.

5. **Stats summary card** (white, rounded) — always visible below menu, 2×2 grid:
   - Top-left: **Resets** count (big number)
   - Top-right: **Since started** (e.g. "27 years") — from `counter.startedAt`
   - Bottom-left: **Longest Streak** (e.g. "27 years")
   - Bottom-right: **Average Streak** (e.g. "27 years")
   - Full unit labels always ("27 Years" not "27y")

### All Resets Screen — `UI Images/from_clicked_on_single_counter_all_resets_button_view.PNG`
- List of past resets for this counter
- Each row: reset date + any note + previous streak duration
- Chronological order, most recent first

### Goals Screen — inferred from `UI Images/concept_Goals_button_from clicked on counter_after_all resets button.PNG`
- List of goals for this counter
- Each goal: target value + unit (e.g. "30 Days") + optional note
- "Add Goal" button — opens a bottom sheet:
  - "Set a goal" title | Cancel / Done
  - Target: number input + unit picker (Days / Weeks / Months / Years)
  - Note: optional text field
- Goals can be marked complete / deleted

### Stats Screen — inferred from `UI Images/concept status after goals button from cllicked on counter view.PNG`
- Header: total reset count + date range
- **Bar chart** (fl_chart `BarChart`): reset frequency
  - Tab selector: Daily / Weekly / Yearly
  - X axis: time periods, Y axis: reset count
  - Bars in accent color

### Reminders Screen
- List of scheduled reminders for this counter
- Each reminder: time + repeat (daily / weekly / custom days)
- Toggle on/off per reminder
- Add reminder → bottom sheet: time picker + repeat selector
- Uses `flutter_local_notifications` — purely local, no server

### Create/Edit Sheet — `UI Images/Create-edit_Counters_view_slide_up.PNG` + `create_edit_counters_view_2_filled.PNG`
- Full-height `showModalBottomSheet` (`isScrollControlled: true`)
- **Header row:** "Cancel" (blue, left) · "Done" (grey when title empty, dark when filled, right)
- **Preview card** (accent color bg): live elapsed display — shows 0 Days / 0 Hours / 0 Minutes / 0 Seconds when creating new; updates live when editing existing
- **Form card** (white, rounded):
  - Title text field — placeholder "e.g. No junk food", no box border, bottom divider only
  - "Started on" row: label left · date chip button · time chip button (right)
  - "Pick a color" row: label left · colored circle (right) — taps open color picker
- Date/time: use built-in `showDatePicker` / `showTimePicker` — works on Android AND web with no wrapper
- Color circle taps → opens `ColorPickerSheet` stacked on top
- Form resets fully on open when creating new; pre-fills when editing

### Color Picker Sheet — `UI Images/Pick_a_color_drawer_view_create-edit_counter_view.PNG`
- Half-height `showModalBottomSheet`
- "Pick a color" title centered · ✕ close button top-right
- Palette name label centered (e.g. "ORIGINALS") — grey caps
- **5-column × 3-row grid** of large color circles
- Selected circle: white ring outline (`BoxDecoration` border)
- **PageView** horizontally — one page per palette (5 palettes)
- Page indicator dots at bottom

### Calendar Tab — `UI Images/Calendar_Tab_1.PNG` + `Calender_Tab_2.PNG`
- "Calendar" centered title · "Filter" blue text button top-right
- `TableCalendar` with custom day cells:
  - Day number at top of cell
  - **Stacked thin horizontal lines** below the number — one line per active counter in that day, each in the counter's accent color
  - Today: outlined rectangle or highlight
- On day tap → updates selected date
- **Bottom panel** (white card, rounded top corners, slides up from bottom half):
  - Selected date header bold (e.g. "2 May")
  - Scrollable list of `CalendarStreakListItem` for that day

### Calendar Streak List Item
- Colored circle bullet · **Counter title** bold · chevron right
- Subtitle: "Day X of Y Days, Z Hours, W Minutes"
- Tap → navigate to counter detail

### Filter Sheet — `UI Images/Filters_slide_up_View-counters_tab.PNG`
- Full-height `showModalBottomSheet`
- "Filter" title centered · "Done" blue text top-right
- "All Counters" row — shows blue checkmark when all selected / none individually selected
- Divider, then scrollable list: colored square bullet + counter name
- Tap row → toggle individual selection (multi-select)
- Selecting individual counters deselects "All Counters" and vice versa
- On "Done": updates calendar filter provider

### Settings — `UI Images/Settings_Tab.PNG`
- "Settings" centered title, no actions
- Grouped white cards separated by spacing (iOS settings style):
  - **Group 1:** Privacy Policy (opens URL), About (AlertDialog with version + description)
  - *(Premium items from original screenshot are omitted — no paid plans in this app)*
- App version at very bottom: "Streak Tracker x.x.x (build N)" — grey small text

---

## Folder Structure

The Flutter project lives directly at the **repo root**. The repo root IS the Flutter project.

```
/ (repo root = Flutter project root)
  lib/
    main.dart               # runApp(ProviderScope(child: StreakTrackerApp()))
    app.dart                # MaterialApp.router — GoRouter + ThemeData

    router/
      app_router.dart       # GoRouter: ShellRoute (tabs) + detail routes

    db/
      db_adapter.dart       # Abstract DbAdapter interface
      db.dart               # createAdapter() — kIsWeb branch
      sqflite_adapter.dart  # Native SQLite implementation
      web_adapter.dart      # Web shared_preferences implementation
      schema.dart           # SQL CREATE TABLE strings

    models/
      counter.dart          # Counter — fromMap, toMap, copyWith
      reset.dart            # Reset — fromMap, toMap
      goal.dart             # Goal — fromMap, toMap, copyWith
      elapsed_time.dart     # ElapsedTime value object
      stats.dart            # Stats value object

    providers/
      db_provider.dart      # dbAdapterProvider
      counter_provider.dart # CountersNotifier (AsyncNotifierProvider)
      calendar_provider.dart # CalendarNotifier — selected date + filter ids
      goal_provider.dart    # GoalsNotifier per counter

    screens/
      counters/
        counters_screen.dart           # 2-col GridView + FAB/+ button
        counter_detail_screen.dart     # Full detail: streak card, reset btn, menu, stats card
        all_resets_screen.dart         # List of past resets for a counter
        goals_screen.dart              # Goals list + add goal sheet
        stats_screen.dart              # Bar chart of reset frequency (fl_chart)
        reminders_screen.dart          # Local notification reminders list
      calendar/
        calendar_screen.dart           # TableCalendar + bottom day panel
      settings/
        settings_screen.dart           # Grouped settings rows

    widgets/                # Reusable Flutter UI components
      counter_card.dart               # Accent card + circle decoration + live time
      live_time_display.dart          # Timer.periodic ticker
      time_tab_selector.dart          # Hours/Days/Weeks/Months/Years segmented bar
      stats_summary_card.dart         # Inline 2×2 stats grid on detail screen
      empty_state.dart                # Empty list illustration + CTA
      calendar_day_cell.dart          # Custom TableCalendar day with stacked lines
      calendar_streak_list_item.dart  # Bottom panel list row

    sheets/
      create_edit_sheet.dart    # Create / edit counter (full-height sheet)
      reset_sheet.dart          # Reset counter: note + date/time
      color_picker_sheet.dart   # Palette PageView + color grid
      filter_sheet.dart         # Calendar filter multi-select
      set_goal_sheet.dart       # Set a goal: target value + unit + note
      add_reminder_sheet.dart   # Add reminder: time + repeat pattern

    utils/
      time_utils.dart       # getElapsed(startMs, nowMs) → ElapsedTime
      stats_utils.dart      # computeStats(counter, resets) → Stats
      format_utils.dart     # formatDate, formatShortDate, formatDuration
      calendar_utils.dart   # buildDayColorMap → Map<DateTime, List<Color>>
      uuid_utils.dart       # generateId() → UUID v4 string

    constants/
      colors.dart           # kColorPalettes: Map<String, List<Color>> (5×15 = 75)
      app_theme.dart        # ThemeData, text styles, layout constants

  android/                  # Standard Flutter Android project files
  web/                      # Standard Flutter Web project files

  android_widgets/          # Separate Flutter entry point for home_widget
    lib/
      main.dart
      counter_widget.dart

  UI Images/                # Design reference screenshots — DO NOT DELETE OR MOVE
    Counters_Tab.PNG
    counter_view_clicked_on_counter_detials_of_single_counter_1.PNG
    counter_view_clicked_on_counter_detials_of_single_counter_2_scrolled.PNG
    counter_view_clicked_on_counter_detials_of_single_counter_clicked_on_reset_counter_button.PNG
    Create-edit_Counters_view_slide_up.PNG
    create_edit_counters_view_2_filled.PNG
    Pick_a_color_drawer_view_create-edit_counter_view.PNG
    Filters_slide_up_View-counters_tab.PNG
    Calendar_Tab_1.PNG
    Calender_Tab_2.PNG
    Settings_Tab.PNG
    from_clicked_on_single_counter_all_resets_button_view.PNG
    concept status after goals button from cllicked on counter view.PNG
    concept_Goals_button_from clicked on counter_after_all resets button.PNG
    widget 1 home screen.PNG
    widget 2 home screen.PNG
    widget 3 home screen.PNG
    widget 4  lock screen the rounded area with showing 146 days.PNG

  pubspec.yaml
  ARCHITECTURE.md
  CONVENTIONS.md
  TASKS.md
  .agents/
    skills/
      flutter-skill.md
  .gitignore
```

---

## Data Models

### Counter
```dart
class Counter {
  final String id;          // UUID v4
  final String title;       // Max 50 chars
  final String color;       // Hex string "#RRGGBB"
  final int startedAt;      // Unix ms — streak start OR last reset timestamp
  final String period;      // 'hours' | 'days' | 'weeks' | 'months' | 'years'
  final int createdAt;      // Unix ms
  final int updatedAt;      // Unix ms
}
```

### Reset
```dart
class Reset {
  final String id;
  final String counterId;         // FK → counter.id
  final int resetAt;              // Unix ms — when reset happened
  final String? note;             // Optional user note
  final int previousStartedAt;    // counter.startedAt snapshot before this reset
  final int createdAt;            // Unix ms
}
```

> **Reset flow:** Insert a `Reset` row with `previousStartedAt = counter.startedAt`, then update `counter.startedAt = DateTime.now().millisecondsSinceEpoch`. Streak timer goes back to 0.

### Goal
```dart
class Goal {
  final String id;
  final String counterId;     // FK → counter.id
  final int targetValue;      // e.g. 30
  final String targetUnit;    // 'days' | 'weeks' | 'months' | 'years'
  final String? note;         // Optional label
  final bool isCompleted;     // Checked off by user
  final int createdAt;        // Unix ms
}
```

### ElapsedTime (computed, never stored)
```dart
class ElapsedTime {
  final int years, months, days, hours, minutes, seconds;
}
// lib/utils/time_utils.dart:
ElapsedTime getElapsed(int startMs, int nowMs);
```

### Stats (computed, never stored)
```dart
class Stats {
  final int resetCount;
  final int longestStreakDays;
  final int averageStreakDays;
  final int daysSinceStart;   // from counter.startedAt, NOT counter.createdAt
}
// lib/utils/stats_utils.dart:
Stats computeStats(Counter counter, List<Reset> resets);
```

---

## SQL Schema (`lib/db/schema.dart`)

```sql
CREATE TABLE IF NOT EXISTS counters (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  color TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  period TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS resets (
  id TEXT PRIMARY KEY,
  counter_id TEXT NOT NULL,
  reset_at INTEGER NOT NULL,
  note TEXT,
  previous_started_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (counter_id) REFERENCES counters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  counter_id TEXT NOT NULL,
  target_value INTEGER NOT NULL,
  target_unit TEXT NOT NULL,
  note TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (counter_id) REFERENCES counters(id) ON DELETE CASCADE
);

PRAGMA foreign_keys = ON;
```

---

## Color System

**75 accent colors — 5 palettes × 15 colors**

Palettes: Originals, Earth Tones, Pastels, Landscapes, Metals.

```dart
// lib/constants/colors.dart
const Map<String, List<Color>> kColorPalettes = { ... };

// Helpers:
String colorToHex(Color c) =>
    '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

Color hexToColor(String hex) =>
    Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

Color randomColor() {
  final all = kColorPalettes.values.expand((l) => l).toList();
  return all[Random().nextInt(all.length)];
}
```

Same color applied to: card background, calendar streak line, detail accent strip, Reset button background, widget background.

---

## Navigation

```dart
// lib/router/app_router.dart
GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/counters', builder: (_, __) => const CountersScreen()),
        GoRoute(path: '/calendar',  builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/counters/:id',
      builder: (_, state) => CounterDetailScreen(id: state.pathParameters['id']!),
      routes: [
        GoRoute(path: 'resets',    builder: (_, state) => AllResetsScreen(counterId: state.pathParameters['id']!)),
        GoRoute(path: 'goals',     builder: (_, state) => GoalsScreen(counterId: state.pathParameters['id']!)),
        GoRoute(path: 'stats',     builder: (_, state) => StatsScreen(counterId: state.pathParameters['id']!)),
        GoRoute(path: 'reminders', builder: (_, state) => RemindersScreen(counterId: state.pathParameters['id']!)),
      ],
    ),
  ],
  redirect: (_, state) => state.uri.path == '/' ? '/counters' : null,
)
```

---

## Real-Time Ticking

```dart
// lib/widgets/live_time_display.dart
class _LiveTimeDisplayState extends State<LiveTimeDisplay> {
  late Timer _timer;
  late ElapsedTime _elapsed;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() => setState(() =>
      _elapsed = getElapsed(widget.startedAt, DateTime.now().millisecondsSinceEpoch));

  @override
  void dispose() { _timer.cancel(); super.dispose(); }
}
```

Always cancel timers in `dispose()` — memory leak if missed.

---

## Android Home Screen Widgets

- **Package:** `home_widget ^0.6.x`
- Save data from main app: `HomeWidget.saveWidgetData<String>('counters_json', json)`
- Trigger update: `HomeWidget.updateWidget(name: 'CounterWidgetProvider')`
- **Small (2×2):** one counter, big number + unit, accent bg — see `UI Images/widget 1 home screen.PNG`
- **Medium (4×2):** up to 3 counters — see `UI Images/widget 2 home screen.PNG`
- **Lock screen:** number + unit in rounded pill — see `UI Images/widget 4 lock screen...`
- All widget code lives in `android_widgets/` — never imported from `lib/`

---

## Build Commands

```bash
# Android — debug APK (fast, for quick testing on device)
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# Android — release APK (optimized, for sharing/sideloading)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Android — App Bundle (for Play Store submission)
flutter build appbundle --release

# Install on connected device
flutter install

# Web — run in Chrome (hot reload)
flutter run -d chrome

# Web — static build
flutter build web --release
# Serve: cd build/web && python -m http.server 8080

# Run on connected Android device
flutter run -d android

# List available devices
flutter devices
```
