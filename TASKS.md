# TASKS.md

> Running checklist for the Flutter rewrite of Streak Tracker.
> Status: ✅ Done | 🔄 In Progress | ⬜ Not Started | 🚫 Blocked

---

## How To Use This File

**Starting a session:**
> "Read ARCHITECTURE.md, CONVENTIONS.md, and TASKS.md. Find the first incomplete task and continue. Open the relevant image from UI Images/ before building any screen."

**Ending a session:** Mark completed tasks ✅, add newly discovered bugs/tasks at the bottom, update Session Notes.

**Switching agents:** ARCHITECTURE.md + CONVENTIONS.md + TASKS.md + UI Images/ is all context needed.

---

## Phase 0 — Project Setup & Scaffold

> Goal: Flutter project at repo root, all deps installed, app boots on Android and Chrome.

- ✅ `0.1` **Verify Flutter environment**
  ```powershell
  flutter doctor -v
  flutter doctor --android-licenses   # accept all
  ```
  Must show: Flutter (stable 3.24.x+), Android toolchain, Chrome all ✓

- ✅ `0.2` **Initialise Flutter project at repo root**
  ```powershell
  # In the cloned repo directory (after git clone https://github.com/Sanju2op/streak-tracker-flutter.git)
  # The old React Native files are already gone — initialise Flutter directly here:
  flutter create . --org com.sanju2op --project-name streak_tracker --platforms android,web
  ```
  - Confirm `pubspec.yaml` appears at root
  - Confirm `UI Images/` folder is untouched

- ✅ `0.3` **Replace `pubspec.yaml` dependencies section**
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    flutter_riverpod: ^2.5.0
    go_router: ^14.0.0
    sqflite: ^2.3.0
    shared_preferences: ^2.2.0
    table_calendar: ^3.1.0
    fl_chart: ^0.68.0
    flutter_local_notifications: ^17.0.0
    permission_handler: ^11.0.0
    home_widget: ^0.6.0
    uuid: ^4.0.0
    intl: ^0.19.0

  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^4.0.0
  ```
  Then: `flutter pub get`

- ✅ `0.4` **Create folder structure** — make all empty directories as defined in ARCHITECTURE.md
  ```
  lib/router/   lib/db/   lib/models/   lib/providers/
  lib/screens/counters/   lib/screens/calendar/   lib/screens/settings/
  lib/widgets/   lib/sheets/   lib/utils/   lib/constants/
  android_widgets/lib/
  .agents/skills/
  ```

- ✅ `0.5` **Commit initial scaffold**
  ```powershell
  git add .
  git commit -m "chore: initialise Flutter project at repo root"
  git push origin main
  ```
  - GitHub CLI installed and authenticated via browser as `Sanju2op`

- ✅ `0.6` **Confirm app boots** — default Flutter counter app should run without errors
  ```powershell
  flutter run -d android
  flutter run -d chrome
  ```
  - Android run skipped by request; debug APK build verified with `flutter build apk --debug -t lib/main.dart`
  - Web build verified with `flutter build web`

---

## Phase 1 — Data Layer

> Goal: All models, DB adapters, providers, and utils implemented and tested. No UI yet.

### Models

- ✅ `1.1` **`lib/models/elapsed_time.dart`**
  ```dart
  class ElapsedTime {
    final int years, months, days, hours, minutes, seconds;
    const ElapsedTime({...});
  }
  ```

- ✅ `1.2` **`lib/models/stats.dart`**
  ```dart
  class Stats {
    final int resetCount;
    final int longestStreakDays;
    final int averageStreakDays;
    final int daysSinceStart;   // from counter.startedAt
    const Stats({...});
  }
  ```

- ✅ `1.3` **`lib/models/counter.dart`**
  - Fields: `id`, `title`, `color` (hex string), `startedAt` (int ms), `period` (string), `createdAt`, `updatedAt`
  - Implement: `fromMap(Map<String,dynamic>)`, `toMap()`, `copyWith(...)`
  - `period` valid values: `'hours' | 'days' | 'weeks' | 'months' | 'years'`

- ✅ `1.4` **`lib/models/reset.dart`**
  - Fields: `id`, `counterId`, `resetAt` (int ms), `note` (nullable String), `previousStartedAt` (int ms), `createdAt`
  - Implement: `fromMap()`, `toMap()`

- ✅ `1.5` **`lib/models/goal.dart`**
  - Fields: `id`, `counterId`, `targetValue` (int), `targetUnit` (string), `note` (nullable), `isCompleted` (bool), `createdAt`
  - `targetUnit` valid values: `'days' | 'weeks' | 'months' | 'years'`
  - Implement: `fromMap()`, `toMap()`, `copyWith(...)`

### Database

- ✅ `1.6` **`lib/db/schema.dart`** — SQL strings, copy from ARCHITECTURE.md exactly

- ✅ `1.7` **`lib/db/db_adapter.dart`** — abstract class, copy from ARCHITECTURE.md exactly

- ✅ `1.8` **`lib/db/sqflite_adapter.dart`** — native SQLite
  - `openDatabase()` → `onCreate` runs all schema SQL from `schema.dart`
  - Enable `PRAGMA foreign_keys = ON` in `onOpen` callback
  - Implement all `DbAdapter` methods with raw SQL
  - `deleteCounter` cascades to resets + goals via FK
  - NEVER import `sqflite` outside this file

- ✅ `1.9` **`lib/db/web_adapter.dart`** — shared_preferences
  - Keys: `st_counters`, `st_resets`, `st_goals` — JSON encoded lists
  - All methods return `Future<T>`
  - Default to `[]` if key missing or JSON malformed
  - `deleteCounter`: filter resets + goals lists in memory, save back
  - NEVER import `shared_preferences` outside this file

- ✅ `1.10` **`lib/db/db.dart`** — `createAdapter()` using `kIsWeb`

- ✅ `1.11` **`lib/providers/db_provider.dart`**
  ```dart
  final dbAdapterProvider = Provider<DbAdapter>((ref) => createAdapter());
  ```

### Utils

- ✅ `1.12` **`lib/utils/uuid_utils.dart`**
  ```dart
  import 'package:uuid/uuid.dart';
  String generateId() => const Uuid().v4();
  ```

- ✅ `1.13` **`lib/utils/time_utils.dart`** — `getElapsed(int startMs, int nowMs) → ElapsedTime`
  - Account for variable month and year lengths (do not just divide by 30 or 365)
  - Use `DateTime` arithmetic for accuracy
  - Also provide unit-specific value helpers:
    - `getElapsedInHours(startMs, nowMs) → double`
    - `getElapsedInDays(startMs, nowMs) → double`
    - `getElapsedInWeeks(startMs, nowMs) → double`
    - (used by TimeTabSelector to show single-unit views)

- ✅ `1.14` **`lib/utils/stats_utils.dart`**
  ```dart
  Stats computeStats(Counter counter, List<Reset> resets);
  ```
  - `resetCount` = `resets.length`
  - `daysSinceStart` = days from `counter.startedAt` to now
  - `longestStreakDays` = longest gap between consecutive reset timestamps (or current if no resets)
  - `averageStreakDays` = mean of all streak gaps (treat current streak as ongoing)
  - Also provide: `buildBarChartData(List<Reset> resets, String period) → List<BarChartGroupData>`
    - `period`: `'daily'` | `'weekly'` | `'yearly'`
    - Returns fl_chart `BarChartGroupData` list grouped by the period

- ✅ `1.15` **`lib/utils/format_utils.dart`**
  - `formatDate(int ms) → String` → "10 Jan 1999"
  - `formatShortDate(int ms) → String` → "10 Jan"
  - `formatTime(int ms) → String` → "7:26 PM"
  - `formatDuration(ElapsedTime e) → String` → "27 Years, 3 Months, 22 Days"
  - `formatPeriodLabel(String period) → String` → "Years" / "Months" etc.

- ✅ `1.16` **`lib/utils/calendar_utils.dart`**
  ```dart
  Map<DateTime, List<Color>> buildDayColorMap(
    List<Counter> counters,
    List<Reset> resets,
    List<String> filterIds,   // empty list = all counters
  );
  ```
  - For each counter: the range it was "active" is `counter.startedAt` → now (no resets), or between consecutive resets
  - Each day in an active range gets the counter's color added to its list
  - Normalise `DateTime` to midnight (`DateTime(y, m, d)`) for map keys
  - `filterIds` non-empty → only include matching counters

### Constants

- ✅ `1.17` **`lib/constants/colors.dart`** — 5 palettes × 15 colors = 75 total
  - Palette names: `'Originals'`, `'Earth Tones'`, `'Pastels'`, `'Landscapes'`, `'Metals'`
  - Match the colors visible in `UI Images/Pick_a_color_drawer_view_create-edit_counter_view.PNG` for Originals
  - Include: `colorToHex(Color)`, `hexToColor(String)`, `randomColor()`

- ✅ `1.18` **`lib/constants/app_theme.dart`**
  ```dart
  const kBgColor     = Color(0xFFF2F2F7);
  const kCardColor   = Colors.white;
  const kAccentBlue  = Color(0xFF007AFF);
  const kTextPrimary = Colors.black;
  const kTextSecondary = Color(0xFF8E8E93);
  const kCardRadius  = BorderRadius.all(Radius.circular(16));
  const kSheetRadius = BorderRadius.vertical(top: Radius.circular(20));
  const kDividerColor = Color(0xFFE5E5EA);
  ```
  - `buildAppTheme() → ThemeData` — Material 3, sets scaffold bg to `kBgColor`, card color, etc.

### Providers (data)

- ✅ `1.19` **`lib/providers/counter_provider.dart`** — `CountersNotifier`
  ```dart
  class CountersNotifier extends AsyncNotifier<List<Counter>> {
    Future<List<Counter>> build() async { ... }
    Future<void> addCounter(Counter c) async { ... }
    Future<void> updateCounter(Counter c) async { ... }
    Future<void> deleteCounter(String id) async { ... }
    Future<void> resetCounter(String id, {String? note, int? resetAt}) async { ... }
  }
  ```
  - `resetCounter`: create `Reset` with `previousStartedAt = counter.startedAt`, then update `counter.startedAt` to `resetAt ?? DateTime.now().ms`
  - After every mutation: `ref.invalidateSelf()` to refresh the list

- ✅ `1.20` **`lib/providers/calendar_provider.dart`** — `CalendarNotifier`
  - State: `(selectedDate: DateTime, filterIds: List<String>)`
  - `selectedDate` defaults to today
  - `setSelectedDate(DateTime d)`
  - `setFilter(List<String> ids)` — empty list = all counters
  - `clearFilter()`

- ✅ `1.21` **`lib/providers/goal_provider.dart`** — `GoalsNotifier`
  - Scoped per `counterId` using `.family`
  - `addGoal(Goal g)`, `toggleComplete(String id)`, `deleteGoal(String id)`

- ✅ `1.22` **Smoke test** — add 2 counters, reset one with a note, add a goal, print all via `debugPrint`. Verify sqflite on Android and web_adapter in Chrome both work.
  - `flutter test -d chrome test/data_layer_smoke_test.dart` verifies the web adapter path.
  - `flutter build apk --debug -t lib/main.dart` verifies the Android/native dependency path builds.

---

## Phase 2 — App Shell

> Goal: Tab navigation working, correct screens render, theme applied everywhere.

- ✅ `2.1` **`lib/constants/app_theme.dart`** — fill out `buildAppTheme()` fully
  - `useMaterial3: true`
  - Bottom nav bar background white
  - App bar background `kBgColor`, elevation 0
  - Card theme: white, `kCardRadius`

- ✅ `2.2` **`lib/router/app_router.dart`** — GoRouter with ShellRoute
  - Copy route structure from ARCHITECTURE.md exactly
  - `ShellRoute` builder: `ScaffoldWithNavBar(child: child)`

- ✅ `2.3` **`ScaffoldWithNavBar` widget** (can live in `lib/router/app_router.dart` or `lib/widgets/`)
  - `BottomNavigationBar` — 3 items: Counters (list icon), Calendar (calendar_month icon), Settings (settings icon)
  - Active item color: `kAccentBlue`
  - Inactive item color: `kTextSecondary`
  - Background: white
  - No elevation shadow (use a top border instead if needed)
  - `onTap`: use `context.go('/counters')` etc.
  - Highlight the correct tab based on `GoRouterState.of(context).uri.path`

- ✅ `2.4` **`lib/app.dart`** — `MaterialApp.router` with `GoRouter` + `buildAppTheme()`

- ✅ `2.5` **`lib/main.dart`**
  ```dart
  void main() => runApp(const ProviderScope(child: StreakTrackerApp()));
  ```

- ✅ `2.6` **Stub all 3 tab screens** — just a `Scaffold` + centered title text for now

- ✅ `2.7` **Verify** — tabs switch correctly, back from detail returns to counters, theme applied
  - Covered by `test/widget_test.dart`.
  - Verified with `flutter analyze`, `flutter test`, `flutter build web`, and `flutter build apk --debug -t lib/main.dart`.

---

## Phase 3 — Counters Feature

> Open `UI Images/Counters_Tab.PNG` and both counter detail images before starting this phase.

### 3A — Counter List Screen

- ✅ `3.1` **`lib/widgets/empty_state.dart`**
  - Center column: an icon (e.g. `Icons.timer_outlined`, large, accent colored), "No counters yet" bold, "Tap + to add your first counter" grey, "Add Counter" outlined button
  - Tapping button fires the create sheet callback

- ✅ `3.2` **`lib/widgets/live_time_display.dart`**
  - `StatefulWidget` — `Timer.periodic(Duration(seconds: 1), ...)` in `initState`
  - Calls `getElapsed(widget.startedAt, DateTime.now().millisecondsSinceEpoch)`
  - Exposes `elapsed` via builder or displays directly
  - **Always cancel timer in `dispose()`**
  - On card: shows primary unit value only (e.g. "27" with "years" below) based on `counter.period`

- ✅ `3.3` **`lib/widgets/counter_card.dart`** — see `UI Images/Counters_Tab.PNG`
  - `Container` with `color: hexToColor(counter.color)`, `borderRadius: kCardRadius`
  - `Stack`: background circle (white, opacity ~0.15, large, positioned bottom-right, overflows)
  - Foreground: large number (white, bold, ~48sp) top-left, unit label (white, ~14sp) below number
  - `ClipRRect` wraps the Stack to prevent circle overflow from showing outside card
  - Below the card in a `Column` (not inside): bold title, grey subtitle
  - Subtitle logic: no resets → "Started on [shortDate]" | has resets → "Reset on [shortDate of last reset]"
  - Full card area is tappable → `context.push('/counters/${counter.id}')`
  - `AspectRatio(aspectRatio: 1.0)` for the card — square cards in the grid

- ✅ `3.4` **`lib/screens/counters/counters_screen.dart`**
  - `AppBar`: sort icon (`Icons.sort`) left, "Counters" centered, `+` icon (`Icons.add`) right
  - Body: `GridView.builder` — `crossAxisCount: 2`, `crossAxisSpacing: 12`, `mainAxisSpacing: 4`, padding 16 all sides
  - Each grid item: `CounterCard` widget
  - Empty state: show `EmptyState` widget when counter list is empty
  - `+` tap AND empty state button → `_openCreateSheet(context)`
  - Background: `kBgColor`
  - Sort icon: opens an `AlertDialog` or bottom sheet with sort options (by name, by date, by streak length) — store sort preference in a simple Riverpod `StateProvider`

### 3B — Create / Edit Sheet

- ✅ `3.5` **`lib/sheets/color_picker_sheet.dart`** — see `UI Images/Pick_a_color_drawer_view_create-edit_counter_view.PNG`
  - `showModalBottomSheet` half-height, `isScrollControlled: false`
  - Header: "Pick a color" centered, ✕ `IconButton` top-right → `Navigator.pop(context, selectedColor)`
  - Palette name label: grey, caps, centered (e.g. "ORIGINALS")
  - `PageView` — one page per palette (5 palettes from `kColorPalettes`)
  - Each page: `GridView` 5 columns × 3 rows of color circles
    - Circle: `InkWell` wrapping a `Container` with `BoxDecoration(shape: BoxShape.circle, color: ...)`
    - Selected: add `border: Border.all(color: Colors.white, width: 3)` + slight scale up
  - Dots page indicator below `PageView`
  - Returns the selected `Color` on pop

- ✅ `3.6` **`lib/sheets/create_edit_sheet.dart`** — see `UI Images/Create-edit_Counters_view_slide_up.PNG` and `create_edit_counters_view_2_filled.PNG`
  - `showModalBottomSheet(isScrollControlled: true, useRootNavigator: true)`
  - `DraggableScrollableSheet` or fixed full-height with `MediaQuery.of(context).size.height`
  - **Header**: "Cancel" `TextButton` (blue) left | "Done" `TextButton` (grey when title empty, dark when non-empty) right
  - **Preview card**: accent color bg, `kCardRadius`, shows live elapsed time — 4 columns: Days / Hours / Minutes / Seconds. When creating new: all 0. Live `LiveTimeDisplay` widget driven by `startedAt` form field value.
  - **Form card** (white, `kCardRadius`):
    - `TextField` — title, placeholder "e.g. No junk food", no box border, only `UnderlineInputBorder` (or bottom divider), `onChanged` updates local state
    - `Divider` (height 1, color `kDividerColor`)
    - "Started on" row: `Text('Started on')` left, `Row([dateChip, SizedBox(8), timeChip])` right
      - Each chip: `OutlinedButton` or `Container` with border radius, shows current date/time value
      - Tap → `showDatePicker(...)` / `showTimePicker(...)` — Flutter built-in, works on both Android and web
    - `Divider`
    - "Pick a color" row: `Text('Pick a color')` left, color circle `GestureDetector` right → opens `ColorPickerSheet` with `await showModalBottomSheet(...)`, sets returned color
  - "Done" taps → validate title non-empty → call `ref.read(countersNotifierProvider.notifier).addCounter(...)` or `.updateCounter(...)` → `Navigator.pop(context)`
  - When editing: pre-fill all fields from the existing `Counter` object passed in

- ✅ `3.7` **Wire** `+` button and Edit button → open `CreateEditSheet` via `showModalBottomSheet`

### 3C — Counter Detail Screen

- ✅ `3.8` **`lib/widgets/time_tab_selector.dart`** — see detail screen image
  - 5 options: Hours · Days · Weeks · Months · Years
  - Each: `GestureDetector` wrapping a `Text`
  - Active tab: black text, bold, wrapped in a rounded `Container` with thin border
  - Inactive: grey text, no border
  - Horizontal `Row` with even spacing

- ✅ `3.9` **`lib/screens/counters/counter_detail_screen.dart`** — see `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_1.PNG` and `..._2_scrolled.PNG`

  **AppBar:**
  - Left: back chevron + "Counters" text (blue), tap → `context.pop()`
  - Center: small accent-colored circle bullet + counter title (as seen in scrolled view AppBar)
  - Right: "Edit" text button → open `CreateEditSheet` pre-filled

  **Body** — `SingleChildScrollView` with `Column`:

  1. **Title block**:
     - `Row`: 4px wide `Container(color: hexToColor(counter.color))` left strip | `Column(title bold, "Started on [fullDate]" grey)` right
     - Padding 16 horizontal

  2. **Current Streak card** (white, `kCardRadius`, margin 16 horizontal):
     - Row: Column("Current Streak" bold 16sp, "Started on [fullDate]" grey 13sp) | Share `OutlinedButton` (blue, share icon)
     - `TimeTabSelector` widget
     - 4-column breakdown Row:
       - Each column: large number (bold, ~36sp) + grey label below
       - What shows depends on selected tab:
         - **Hours** tab: shows total hours / minutes / seconds / — (or just H/M/S)
         - **Days** tab: shows Days / Hours / Minutes / Seconds
         - **Weeks** tab: shows Weeks / Days / Hours / Minutes
         - **Months** tab: shows Months / Days / Hours / Minutes
         - **Years** tab: shows Years / Months / Days / Hours  ← default

  3. **Reset Counter button**:
     - `ElevatedButton`, full width, `hexToColor(counter.color)` bg, white text bold
     - `BorderRadius.circular(12)`, height 52
     - Tap → open `ResetSheet`

  4. **Menu list card** (white, `kCardRadius`, margin 16 horizontal):
     - 4 rows, each: leading icon (accent color, square bg rounded), title text, trailing chevron
     - Row 1: stacked squares icon → "All Resets" → `context.push('/counters/${id}/resets')`
     - Row 2: target icon → "Goals" → `context.push('/counters/${id}/goals')`
     - Row 3: bar chart icon → "Stats" → `context.push('/counters/${id}/stats')`
     - Row 4: bell icon → "Reminders" → `context.push('/counters/${id}/reminders')`
     - Each row separated by `Divider(indent: 56, height: 1)`

  5. **Stats summary card** (white, `kCardRadius`, margin 16 horizontal) — always visible, no tap needed:
     - "Stats" bold label top-left of card
     - 2×2 `GridView` or 2-row layout:
       - Top row: "0 · Resets" | "27 years · Since started"
       - Bottom row: "27 years · Longest Streak" | "27 years · Average Streak"
     - Large bold number, grey label below each

- ✅ `3.10` **`lib/sheets/reset_sheet.dart`** — see `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_clicked_on_reset_counter_button.PNG`
  - `showModalBottomSheet` half-height
  - Title: "Reset [counter.title]"
  - Optional note `TextField` ("Add a note…")
  - "Reset date" row with date + time chips (default: now, tappable to change)
  - Full-width "Reset Counter" button (accent color) — calls `resetCounter(id, note: note, resetAt: chosenTime)`
  - "Cancel" link below button

### 3D — All Resets Screen

- ✅ `3.11` **`lib/screens/counters/all_resets_screen.dart`** — see `UI Images/from_clicked_on_single_counter_all_resets_button_view.PNG`
  - AppBar: back arrow, "All Resets" title, counter title subtitle OR accent color dot
  - `FutureProvider` / load resets from DB for this `counterId`
  - `ListView` of reset entries, most recent first
  - Each row:
    - Date + time (formatted)
    - Note text if present (grey, smaller)
    - Previous streak duration (e.g. "Streak: 2 Years, 3 Days")
    - Subtle `Divider` between rows
  - Empty state: "No resets yet" centered

- ✅ `3.12` **`lib/sheets/reset_drawer_sheet.dart`** — see `UI Images/clicked on single reset from all resets screen drawer view.jpeg`
  - `showModalBottomSheet` half-height
  - Header: "Cancel" left | "Edit" right
  - Card 1: Counter title, Date range (e.g., "7 Dec 2025 - 7 Dec 2025"), "Share" button
  - Below Card 1: 4 columns for elapsed streak time for that reset (Days, Hours, Minutes, Seconds)
  - Card 2: "Reset on" and the date + time of the reset

- ✅ `3.13` **`lib/sheets/edit_reset_sheet.dart`** — see `UI Images/clicked on single reset from all resets then clicked edit from drawer screen drawer view.jpeg`
  - Opens when "Edit" is clicked from Reset Drawer
  - Header: "Cancel" left | "Done" right
  - Card 1: "Reset on" row with date and time chips, "Note" text field
  - Card 2: "Delete Reset" (red text) button
---

## Phase 4 — Goals Feature

> Open `UI Images/concept_Goals_button_from clicked on counter_after_all resets button.PNG` before starting.

- ✅ `4.1` **`lib/sheets/set_goal_sheet.dart`**
  - `showModalBottomSheet` half-height
  - Header: "Cancel" left | "Set a goal" centered | "Done" right
  - "Target" row: number `TextField` + unit `DropdownButton` (Days / Weeks / Months / Years)
  - "Note" `TextField` (optional, "Add a note…")
  - "Done" → `ref.read(goalsNotifierProvider(counterId).notifier).addGoal(goal)` → pop

- ⬜ `4.2` **`lib/screens/counters/goals_screen.dart`**
  - AppBar: back arrow, "Goals" title
  - `ListView` of goals:
    - Each row: target value + unit (e.g. "30 Days"), note if set, checkbox for completion
    - Completed: strikethrough text, muted
    - Swipe to delete (use `Dismissible`)
  - FAB or "Add Goal" button → opens `SetGoalSheet`
  - Empty state: "No goals set" + "Challenge yourself" caption + Add button

---

## Phase 5 — Stats Feature

> Open `UI Images/concept status after goals button from cllicked on counter view.PNG` before starting.

- ⬜ `5.1` **`lib/screens/counters/stats_screen.dart`**
  - AppBar: back arrow, "Stats" title
  - Header row: "TOTAL · X resets · [startDate] – Now"
  - **Tab selector**: Daily / Weekly / Yearly (3 tabs, not 5)
  - **`BarChart`** (fl_chart):
    - Bars in `hexToColor(counter.color)`
    - X axis: time labels (day names, week numbers, or year numbers)
    - Y axis: reset count
    - `barGroups` generated by `buildBarChartData(resets, period)` from `stats_utils.dart`
  - Padding 16 all sides
  - If no resets: show "No resets yet" placeholder instead of chart

- ⬜ `5.2` **`buildBarChartData`** in `lib/utils/stats_utils.dart`
  - `'daily'`: group resets by day of week (Mon–Sun), count per day
  - `'weekly'`: group by ISO week number, last 12 weeks
  - `'yearly'`: group by year, all years from first reset to now

---

## Phase 6 — Reminders Feature

> Fully local — no server, no Firebase. Android 13+ requires runtime notification permission.

- ⬜ `6.1` **Android manifest setup**
  - Add to `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    ```
  - Add the notification receiver and service entries required by `flutter_local_notifications` (see package README for exact XML)

- ⬜ `6.2` **`lib/utils/notification_utils.dart`**
  - `initNotifications()` — initialise `FlutterLocalNotificationsPlugin` in `main.dart`
  - `requestPermission()` — use `permission_handler` to request `Permission.notification` on Android 13+
  - `scheduleReminder(String id, String title, DateTime time, RepeatInterval repeat)`
  - `cancelReminder(String id)`
  - Gate all notification calls with `if (!kIsWeb)` — notifications are Android only in v1

- ⬜ `6.3` **`lib/sheets/add_reminder_sheet.dart`**
  - `showModalBottomSheet` half-height
  - "Add Reminder" title
  - Time picker row (tappable chip → `showTimePicker`)
  - Repeat selector: None / Daily / Weekly / Custom days (checkbox per day: Mon Tue Wed…)
  - "Save" button → schedule via `notification_utils.dart` → pop

- ⬜ `6.4` **`lib/screens/counters/reminders_screen.dart`**
  - AppBar: back arrow, "Reminders" title
  - List of scheduled reminders:
    - Time + repeat pattern
    - `Switch` to enable/disable
    - Swipe to delete (cancel notification + remove from list)
  - FAB / "Add Reminder" button → opens `AddReminderSheet`
  - Empty state: "No reminders set" + add button
  - Note: reminders are stored in `shared_preferences` (a simple JSON list per counter) — no DB table needed

---

## Phase 7 — Calendar Feature

> Open `UI Images/Calendar_Tab_1.PNG` and `Calender_Tab_2.PNG` before starting.

- ⬜ `7.1` **`lib/utils/calendar_utils.dart`** — `buildDayColorMap(...)` — see ARCHITECTURE.md for spec

- ⬜ `7.2` **`lib/widgets/calendar_day_cell.dart`**
  - Custom `TableCalendar` day cell builder
  - Day number at top (bold if today, blue if selected)
  - Stacked thin horizontal lines below number, one per counter active on that day
  - Each line height: ~2–3px, full cell width, in the counter's accent color
  - Today indicator: thin rectangle border around whole cell
  - Selected day: filled or outlined rectangle (blue)

- ⬜ `7.3` **`lib/widgets/calendar_streak_list_item.dart`**
  - `ListTile`-like row:
    - Leading: solid colored circle (counter's accent color, ~10px diameter)
    - Title: counter name (bold)
    - Subtitle: "Day X of Y Days, Z Hours, W Minutes"
    - Trailing: `Icon(Icons.chevron_right)`
  - Full row tappable → `context.push('/counters/${counter.id}')`

- ⬜ `7.4` **`lib/screens/calendar/calendar_screen.dart`**
  - AppBar: "Calendar" centered, "Filter" blue `TextButton` right
  - `TableCalendar`:
    - `firstDay`: earliest counter start date (or 2 years ago)
    - `lastDay`: today
    - `focusedDay`: from `calendarProvider.selectedDate`
    - `selectedDayPredicate`: matches `calendarProvider.selectedDate`
    - `onDaySelected`: `ref.read(calendarProvider.notifier).setSelectedDate(day)`
    - `calendarBuilders.defaultBuilder`: returns `CalendarDayCell`
    - Disable default event markers
    - `headerStyle`: month+year left-aligned, no chevron arrows inside header (use TableCalendar's built-in or custom)
    - `daysOfWeekStyle`: grey, 3-letter abbreviated (SUN, MON…)
  - Body below calendar: white rounded-top card (`kSheetRadius`)
    - Header: selected date bold (e.g. "2 May")
    - `ListView.separated` of `CalendarStreakListItem` — filtered counters active on that day
    - Empty: "No counters on this day"
  - "Filter" button → opens `FilterSheet`

- ⬜ `7.5` **`lib/sheets/filter_sheet.dart`** — see `UI Images/Filters_slide_up_View-counters_tab.PNG`
  - Full-height `showModalBottomSheet(isScrollControlled: true)`
  - Header: "Filter" centered, "Done" blue `TextButton` right
  - "All Counters" row: right checkmark `Icon` (blue) when `filterIds` is empty
  - `Divider`
  - `ListView` of all counters: colored square left, counter name, `Checkbox` or tap toggle right
  - Multi-select: tapping individual counter adds/removes from selection
  - Tapping "All Counters" clears individual selections
  - "Done" → `ref.read(calendarProvider.notifier).setFilter(selectedIds)` → `Navigator.pop`

---

## Phase 8 — Settings

> Open `UI Images/Settings_Tab.PNG` before starting.

- ⬜ `8.1` **`lib/screens/settings/settings_screen.dart`**
  - AppBar: "Settings" centered, no actions, no back button (it's a tab)
  - Body `ListView`:
    - **Group 1** (white card, `kCardRadius`):
      - "Privacy Policy" row → opens URL (use `url_launcher` or `launchUrl`)
      - Divider
      - "About" row → `showAboutDialog(context, applicationName: 'Streak Tracker', applicationVersion: '1.0.0', children: [Text('A free Days Since tracker for Android.')])`
    - Spacer
    - **Group 2** (white card, `kCardRadius`):
      - "Tell a Friend" row → `Share.share(...)` using `share_plus` package (add to pubspec if including this)
  - Bottom: version text "Streak Tracker 1.0.0 (build 1)" grey centered

- ⬜ `8.2` Add `url_launcher` to pubspec if including Privacy Policy link
  ```yaml
  url_launcher: ^6.3.0
  ```

---

## Phase 9 — Android Home Screen Widgets

> All widget code lives in `android_widgets/`. Open all 4 widget images before starting.

- ⬜ `9.1` **Read `home_widget` README** in full before starting: https://pub.dev/packages/home_widget

- ⬜ `9.2` **Data bridge** — save top counters data from main app
  - Call on app resume + foreground:
    ```dart
    final data = counters.take(3).map((c) => {...}).toList();
    await HomeWidget.saveWidgetData<String>('counters_json', jsonEncode(data));
    await HomeWidget.updateWidget(name: 'CounterWidgetProvider');
    ```
  - Implement in `CountersScreen` `initState` or a Riverpod listener

- ⬜ `9.3` **Small widget (2×2)** — see `UI Images/widget 1 home screen.PNG`
  - Accent color background, large number + unit, counter name

- ⬜ `9.4` **Medium widget (4×2)** — see `UI Images/widget 2 home screen.PNG`
  - Up to 3 counters side by side

- ⬜ `9.5` **Lock screen widget** — see `UI Images/widget 4 lock screen...PNG`
  - Rounded pill, single counter, number + unit

- ⬜ `9.6` **Register widgets** in `android/app/src/main/AndroidManifest.xml`

- ⬜ `9.7` **Test on real Android device** — widget rendering is unreliable in emulators

---

## Phase 10 — Theme System & UI Animations

> Goal: Light/dark theme with system-sync + manual toggle. Fluid, premium animations
> throughout the app — tab transitions, sheet entrances, card interactions.
> No iOS-specific APIs. Everything via Flutter's built-in animation system.

---

### 10A — Light / Dark Theme

- ⬜ `10.1` **Expand `lib/constants/app_theme.dart`** — define both themes

  Add a dark variant alongside the existing light constants:
  ```dart
  // Light (already exists)
  const kBgColorLight       = Color(0xFFF2F2F7);
  const kCardColorLight     = Colors.white;
  const kTextPrimaryLight   = Colors.black;
  const kTextSecondaryLight = Color(0xFF8E8E93);
  const kDividerColorLight  = Color(0xFFE5E5EA);

  // Dark
  const kBgColorDark        = Color(0xFF1C1C1E);
  const kCardColorDark      = Color(0xFF2C2C2E);
  const kTextPrimaryDark    = Colors.white;
  const kTextSecondaryDark  = Color(0xFF98989D);
  const kDividerColorDark   = Color(0xFF38383A);

  // Accent — same in both
  const kAccentBlue         = Color(0xFF007AFF);
  ```

  Add two `ThemeData` builders:
  ```dart
  ThemeData buildLightTheme();
  ThemeData buildDarkTheme();
  ```

- ⬜ `10.2` **`lib/providers/theme_provider.dart`** — manual theme preference

  ```dart
  // Persists to shared_preferences under key 'st_theme_mode'
  // Values: 'system' | 'light' | 'dark'

  final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
    ThemeModeNotifier.new,
  );

  class ThemeModeNotifier extends Notifier<ThemeMode> {
    @override
    ThemeMode build() {
      // load from shared_preferences on init, default to ThemeMode.system
    }

    Future<void> setThemeMode(ThemeMode mode) async {
      // persist to shared_preferences, update state
    }
  }
  ```

- ⬜ `10.3` **Wire theme into `lib/app.dart`**

  ```dart
  // MaterialApp.router:
  theme:      buildLightTheme(),
  darkTheme:  buildDarkTheme(),
  themeMode:  ref.watch(themeModeProvider),  // system / light / dark
  ```

  When `ThemeMode.system` is selected, Flutter automatically follows
  Android system dark mode — no extra code needed.

- ⬜ `10.4` **Settings toggle UI** — add to `lib/screens/settings/settings_screen.dart`

  Add a new group card at the top of the settings list:

  ```
  ┌─────────────────────────────────────┐
  │  🌓  Appearance                      │
  │  ─────────────────────────────────  │
  │  [System] [Light] [Dark]  ← 3-way  │
  │  segmented control                  │
  └─────────────────────────────────────┘
  ```

  - Use a `SegmentedButton<ThemeMode>` (Material 3 built-in)
  - Selected segment calls `ref.read(themeModeProvider.notifier).setThemeMode(mode)`
  - No restart required — `MaterialApp` reacts immediately

- ⬜ `10.5` **Audit all hardcoded colors** — replace with `Theme.of(context)` lookups

  Create helper extension in `app_theme.dart`:
  ```dart
  extension AppColors on BuildContext {
    Color get bgColor    => Theme.of(this).scaffoldBackgroundColor;
    Color get cardColor  => Theme.of(this).cardColor;
    Color get textPrimary   => Theme.of(this).colorScheme.onSurface;
    Color get textSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
    Color get dividerColor  => Theme.of(this).dividerColor;
  }
  ```

  Everywhere a widget currently uses `kBgColor`, `kCardColor`, etc. directly,
  replace with `context.bgColor`, `context.cardColor`, etc.
  Counter accent colors (`hexToColor(counter.color)`) stay as-is — they're
  user-chosen and look fine on both themes.

---

### 10B — UI Animations

> Philosophy: animations should feel fluid and intentional, not flashy.
> Target: the layered glass + blur aesthetic of modern mobile UIs.
> All via Flutter built-ins — no animation packages needed.

- ⬜ `10.6` **Tab switching animation** — replace default left/right slide

  In `lib/router/app_router.dart`, override the `ShellRoute` page transition:

  ```dart
  // Custom page builder for shell child routes
  pageBuilder: (context, state, child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade + subtle scale-up (feels like depth, not a slide)
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
  ```

  This replaces the odd left-right slide with a subtle fade+scale that reads
  as depth rather than a page flip — works on all 3 tabs.

- ⬜ `10.7` **Route push animation** — counter list → counter detail

  In the `/counters/:id` `GoRoute`, add a custom `pageBuilder`:
  ```dart
  // Slide up + fade in (feels like the detail is rising from the card)
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(position: slide, child: child),
    );
  }
  ```

  Apply the same to all sub-routes (resets, goals, stats, reminders).

- ⬜ `10.8` **Bottom sheet entrance** — blur backdrop + slide up

  Create a helper `showAppBottomSheet(...)` in `lib/utils/sheet_utils.dart`
  that wraps `showModalBottomSheet` with consistent config:

  ```dart
  Future<T?> showAppBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool fullHeight = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: fullHeight,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _BlurSheetWrapper(fullHeight: fullHeight, child: child),
    );
  }
  ```

  `_BlurSheetWrapper` widget:
  ```dart
  // Applies backdrop blur behind the sheet
  class _BlurSheetWrapper extends StatelessWidget {
    Widget build(BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor.withOpacity(0.92),
            borderRadius: kSheetRadius,
          ),
          child: child,
        ),
      );
    }
  }
  ```

  Import: `import 'dart:ui' show ImageFilter;`

  Replace ALL existing `showModalBottomSheet` calls across the app with
  `showAppBottomSheet(...)`. This makes every sheet entrance consistent:
  blurred backdrop, card slides up with the sheet, no hardcoded white background.

- ⬜ `10.9` **Counter card tap feedback** — press scale animation

  Wrap `CounterCard` tap area with `AnimatedScale` or `GestureDetector` +
  `AnimationController`:

  ```dart
  // Simple approach using TweenAnimationBuilder
  TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.0, end: _isPressed ? 0.96 : 1.0),
    duration: const Duration(milliseconds: 100),
    curve: Curves.easeOut,
    builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
    child: counterCardContent,
  )
  ```

  Set `_isPressed` true in `onTapDown`, false in `onTapUp`/`onTapCancel`.
  This gives every card a satisfying physical press feel.

- ⬜ `10.10` **Counter list entrance** — staggered card animation on first load

  When `CountersScreen` transitions from loading → data, animate cards in
  with a staggered fade+slide:

  ```dart
  // Each card delays by: index * 60ms
  // Each card: fade 0→1 + slide from y+20 to y=0
  // Total duration: 300ms per card
  // Use AnimationController in CountersScreen StatefulWidget
  // Drive with: CurvedAnimation(curve: Interval(start, end, curve: Curves.easeOutCubic))
  ```

  Use a single `AnimationController` with multiple `Interval`-based animations,
  one per card. Cap at 6 cards animating (after that, just show immediately —
  long lists don't need stagger on every item).

- ⬜ `10.11` **Live time display pulse** — subtle tick animation

  In `LiveTimeDisplay`, every time the number changes (every second on the
  card's primary value), briefly scale the number up then back:

  ```dart
  // On each _tick():
  // 1. Run a 150ms animation: scale 1.0 → 1.08 → 1.0
  // 2. Curve: Curves.easeInOut
  // Only animate the primary large number, not the unit label
  ```

  This makes the counter feel alive without being distracting. Note: only add it to `CounterCard` — not to the detail screen's large breakdown numbers, where it would look chaotic.

- ⬜ `10.12` **App bar blur on scroll** — frosted glass app bar

  For `CountersScreen` and `CalendarScreen`, replace the default `AppBar`
  with a custom sliver that becomes frosted when content scrolls beneath it:

  ```dart
  SliverAppBar(
    pinned: true,
    backgroundColor: Colors.transparent,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: context.bgColor.withOpacity(0.75),
        ),
      ),
    ),
    title: const Text('Counters'),
  )
  ```

  On dark theme: `bgColor.withOpacity(0.80)`.
  On light theme: `bgColor.withOpacity(0.75)`.
  This is the exact pattern iOS uses for its navigation bar blur.

- ⬜ `10.13` **Verify animations on real Android device**

  Test each animation on actual hardware — emulator rendering of blur
  (`BackdropFilter`) can be slow. If `BackdropFilter` causes frame drops
  on lower-end devices:
  - Reduce `sigmaX`/`sigmaY` from 20 → 12
  - Or gate blur with a `_enableBlur` flag, default true, disable if
    `MediaQuery.of(context).disableAnimations` is true (accessibility setting)

  Target: 60fps on mid-range Android (e.g. Snapdragon 6xx class).

---

## Phase 11 — Polish & Pre-Launch

- ⬜ `11.1` **Loading states** — `CircularProgressIndicator` while DB loads on cold start

- ⬜ `11.2` **Error states** — show a "Something went wrong" + retry button if DB throws

- ⬜ `11.3` **Input validation**
  - Title max 50 chars — enforce in `CreateEditSheet`
  - Reset date cannot be before `counter.startedAt` — validate in `ResetSheet`
  - Goal target value must be > 0

- ⬜ `11.4` **Delete counter confirmation** — `AlertDialog` with "Delete" (red) / "Cancel" before deleting

- ⬜ `11.5` **Sort counters** — implement the sort options from the sort icon in `CountersScreen`
  - Options: Date added (default), Name A→Z, Streak length (longest first)
  - Persist sort preference via `shared_preferences`

- ⬜ `11.6` **Dark mode** — implement `ThemeData.dark()` variant, respect system `Brightness`

- ⬜ `11.7` **App icon**
  - Add `flutter_launcher_icons: ^0.14.0` to dev_dependencies
  - Create 1024×1024 icon image
  - Configure and run: `dart run flutter_launcher_icons`

- ⬜ `11.8` **Splash screen**
  - Add `flutter_native_splash: ^2.4.0` to dev_dependencies
  - Configure and run: `dart run flutter_native_splash:create`

- ⬜ `11.9` **`android/app/build.gradle` final config**
  ```gradle
  applicationId "com.sanju2op.streaktracker"
  minSdkVersion 21
  targetSdkVersion 34
  versionCode 1
  versionName "1.0.0"
  ```

- ⬜ `11.10` **Full test run**
  - Android: all screens, create/edit/delete counter, reset, goals, stats chart, reminders, calendar filter, widgets
  - Chrome: all screens except widgets and reminders (notification/widget are Android-only)

- ⬜ `11.11` **`flutter analyze`** — zero warnings, zero errors

- ⬜ `11.12` **Release build**
  ```powershell
  flutter build appbundle --release
  ```
  Verify build succeeds before Play Store submission.

- ⬜ `11.13` **Google Play Console** ($25 one-time)
  - Create app listing
  - Upload AAB
  - Add Privacy Policy URL
  - Submit for review

---

## Known Issues / Bugs

> Add issues here as discovered during development.

- ✅ `BUG-1` **Current Streak Subtitle incorrect after reset**
  Platform: Both
  Steps to reproduce: View a counter with resets in the Counter Detail Screen.
  Expected: The grey text under "Current Streak" should say "Reset on [Date]" (from the latest reset). The grey text directly under the main title should say "Started on [Original Start Date]".
  Actual: Both places say "Started on [Original Start Date]".
  Fix approach: Update `CounterDetailScreen` to conditionally render the correct text based on resets.

- ✅ `BUG-2` **AppBar title visibility**
  Platform: Both
  Steps to reproduce: Open a counter.
  Expected: The AppBar title (square dot + Counter Title) should only be visible when scrolled down.
  Actual: It is always visible.
  Fix approach: Add a scroll listener or use `SliverAppBar` to toggle title opacity based on scroll position.

- ✅ `BUG-3` **TimeTabSelector design**
  Platform: Both
  Steps to reproduce: View the TimeTabSelector in a counter.
  Expected: Should look like merged buttons with a grey background wrapper (like an iOS segmented control) and should not overflow horizontally.
  Actual: Missing background wrapper, and horizontally overflowing.
  Fix approach: Wrap tabs in a container with `kBgColor` and adjust padding/flex to prevent overflow.

- ✅ `BUG-4` **LiveTimeDisplay text wrapping**
  Platform: Both
  Steps to reproduce: Wait a long time (e.g., 8046 days) so the number becomes large.
  Expected: Text should shrink to fit, no wrapping.
  Actual: Text wraps below, breaking the UI layout.
  Fix approach: Wrap the large number `Text` in a `FittedBox(fit: BoxFit.scaleDown)`.

- ✅ `BUG-5` **Empty 4th column in LiveTimeDisplay**
  Platform: Both
  Steps to reproduce: Select "Hours" tab.
  Expected: Only Hours, Minutes, Seconds are displayed. The 4th column is hidden.
  Actual: Displays a 0 with an empty label for the 4th column.
  Fix approach: Conditionally render the 4th column in `LiveTimeDisplay` only if it's needed for that time format.

- ✅ `BUG-6` **Period selection persistence**
  Platform: Both
  Steps to reproduce: Open a counter, change the time tab (e.g., to "Days"), go back, open it again.
  Expected: The tab selection should persist per-counter, and the main CounterCard on the list screen should display the elapsed time in the newly selected unit.
  Actual: The detail screen always defaults to "Years", and the list screen doesn't reflect the change.
  Fix approach: Remove local ephemeral state for the selected period in `CounterDetailScreen`. Use `counter.period` directly, and trigger `updateCounter` when a tab is tapped.

- ✅ `BUG-7` **Stats sync with time period**
  Platform: Both
  Steps to reproduce: Open a counter details screen and select a time period like "Hours" or "Years".
  Expected: The stats card at the bottom should display the data scaled to the selected time period (e.g., in Hours or Years).
  Actual: The stats card was independently deciding whether to show Days, Months, or Years based on magnitude.
  Fix approach: Pass the `period` from the counter down to `StatsSummaryCard` and format the days dynamically.

Template for new issues:
```
- ⬜ `BUG-X` **Short title**
  Platform: Android / Web / Both
  Steps to reproduce:
  Expected:
  Actual:
  Fix approach:
```

---

## Session Notes

```
Last updated: 2026-05-03
Current focus: Phase 4 — goals feature
Last completed task: 4.1 (lib/sheets/set_goal_sheet.dart)
Next task: 4.2 (lib/screens/counters/goals_screen.dart)

Git remote: https://github.com/Sanju2op/streak-tracker-flutter.git
Branch: main
Flutter channel: stable
Flutter version: 3.41.9 at C:\flutter
Android SDK: 36.0.0 at C:\Users\Sanjay\AppData\Local\Android\Sdk
Dart version: 3.11.5

Key decisions made this session:
  - All features free (Goals, Stats, Reminders, Widgets) — no paid tiers
  - No cloud database — fully local (sqflite on Android, shared_preferences on Web)
  - Flutter project at repo root (replaces React Native code entirely)
  - Android primary target; Web for testing; iOS future
  - UI Images/ is authoritative design source — screenshots take priority over text
  - Flutter 3.41.9 (newer than ARCHITECTURE.md's 3.24.x+ minimum) — fully compatible
  - Web build command changed in Flutter 3.41.9: `flutter build web --web-renderer canvaskit` is rejected, while `flutter build web` succeeds.
  - Android debug APK build passes with `flutter build apk --debug -t lib/main.dart`.
  - `flutter_local_notifications` requires Android core library desugaring; this is enabled in `android/app/build.gradle.kts`.
  - Phase 1 completed with `flutter analyze`, `flutter test`, Chrome data-layer smoke test, web build, and Android debug APK build passing.
  - `scratch/**` is excluded from analyzer input so local scratch files do not affect project analysis.
  - Phase 2 completed with GoRouter shell navigation, tab scaffold, stub screens, ProviderScope app entrypoint, and passing web/Android builds.
  - Phase 3 references opened before widget work: `Counters_Tab.PNG`, `counter_view_clicked_on_counter_detials_of_single_counter_1.PNG`, and `counter_view_clicked_on_counter_detials_of_single_counter_2_scrolled.PNG`.
  - Tasks 3.2–3.4: LiveTimeDisplay (Timer.periodic ticker), CounterCard (accent card + circle decoration), CountersScreen (GridView + sort + empty state). Widget test updated with FakeDbAdapter.
  - Tasks 3.5–3.7: ColorPickerSheet (PageView palettes + dot indicators), CreateEditSheet (full-height modal, preview card with live time, title/date/time/color form, delete in edit mode), wired + button and empty state to open sheet.
```
