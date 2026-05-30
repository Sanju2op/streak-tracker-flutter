# Conventions & Architecture Compliance Report
>
> Streak Tracker Flutter — Auditing implementation against ARCHITECTURE.md, CONVENTIONS.md, and TASKS.md

---

## Overview

This report compares the current codebase against the project's own specification documents. It is split into two sections:

- **Compliant** — where the code correctly follows the MD files
- **Non-Compliant / Corrections Needed** — specific deviations with exact file locations and fixes

---

## Section A — What the Project Gets Right

These areas correctly follow the MD specification and require no changes.

### Data Layer (ARCHITECTURE.md)

- `lib/db/db_adapter.dart` — abstract interface matches spec exactly.
- `lib/db/db.dart` — `createAdapter()` correctly uses `kIsWeb` for platform branching.
- `lib/db/sqflite_adapter.dart` — `PRAGMA foreign_keys = ON` is called in `onOpen`; `sqflite` is never imported outside this file.
- `lib/db/web_adapter.dart` — uses keys `st_counters`, `st_resets`, `st_goals` exactly as specified; `shared_preferences` is never imported outside this file.

### Navigation (ARCHITECTURE.md)

- `lib/router/app_router.dart` — `GoRouter` with `ShellRoute` matches the spec. All tab routes (`/counters`, `/calendar`, `/settings`) and sub-routes (`/counters/:id/resets`, `/goals`, `/stats`, `/reminders`) are correctly implemented. `context.go()` and `context.push()` are used; no raw `Navigator.push()` for routed screens.
- The redirect `state.uri.path == '/' ? '/counters' : null` is implemented.

### State Management (CONVENTIONS.md)

- Screens use `ConsumerWidget` or `ConsumerStatefulWidget` consistently.
- Business logic lives in `AsyncNotifierProvider` (counters, goals) and `NotifierProvider` (theme, sort).
- Local form state in sheets uses `StatefulWidget` + `setState`.

### Models (ARCHITECTURE.md)

- All 5 models (`Counter`, `Reset`, `Goal`, `ElapsedTime`, `Stats`) exist with correct fields.
- `Counter.period` valid values `'hours' | 'days' | 'weeks' | 'months' | 'years'` are enforced in usage.
- All timestamps stored as `int` (Unix ms).

### Color System (ARCHITECTURE.md)

- 75 colors across 5 palettes (`Originals`, `Earth Tones`, `Pastels`, `Landscapes`, `Metals`) in `lib/constants/colors.dart`.
- `colorToHex()`, `hexToColor()`, `randomColor()` all implemented correctly.

### Package Compliance (ARCHITECTURE.md)

- No forbidden packages (`GetX`, `bloc`, `drift`, `hive`) are present in `pubspec.yaml`.
- FFI-dependent packages are absent — web build is safe.

### Null Safety (CONVENTIONS.md)

- Force-unwrap `!` in `_CreateEditSheetState.initState()` is accompanied by a comment: `// safe — guarded by _isEditing`. Compliant.
- No `dynamic` types found in reviewed files.

---

## Section B — Non-Compliant Items (Corrections Required)

Each item below identifies the specific rule being violated, the file and location, and the exact correction.

---

### B-1. Hardcoded Color Constants in `empty_state.dart`

**Rule violated:** CONVENTIONS.md — *"No Hardcoded Values — Colors → `lib/constants/colors.dart`"*; also `app_theme.dart` — *"Always use `context.textPrimary` / `context.textSecondary` not the `k*` constants directly in widgets"*

**File:** `lib/widgets/empty_state.dart`

**Lines affected:**

```dart
// Line ~23 — uses kTextPrimary directly; breaks dark mode
style: textTheme.titleLarge?.copyWith(
  color: kTextPrimary,         // ← VIOLATION
  fontWeight: FontWeight.w700,
),

// Line ~30 — uses kTextSecondary directly; breaks dark mode
style: textTheme.bodyMedium?.copyWith(color: kTextSecondary), // ← VIOLATION
```

**Why it matters:** In dark mode, `kTextPrimary` is `Colors.black` — the text becomes invisible on a dark scaffold background. This is a real dark-mode regression.

**Correction:**

```dart
// Fix line ~23:
style: textTheme.titleLarge?.copyWith(
  color: context.textPrimary,  // ← use context extension
  fontWeight: FontWeight.w700,
),

// Fix line ~30:
style: textTheme.bodyMedium?.copyWith(color: context.textSecondary),
```

---

### B-2. Settings AppBar Does Not Follow the Frosted Glass Pattern

**Rule violated:** TASKS.md Phase `10.12` — *"For `CountersScreen` and `CalendarScreen`, replace the default `AppBar` with a custom sliver that becomes frosted when content scrolls beneath it"*; and ARCHITECTURE.md — *"App bar background `kBgColor`, elevation 0"*

**File:** `lib/screens/settings/settings_screen.dart`

**Lines affected:**

```dart
// Settings uses a solid-color AppBar with no blur:
appBar: AppBar(
  backgroundColor: context.bgColor,    // ← solid; no blur
  elevation: 0,
  centerTitle: true,
  ...
),
```

**Why it matters:** All other screens use `backgroundColor: Colors.transparent` with `flexibleSpace: BackdropFilter(...)`. The solid Settings AppBar breaks the "frosted glass" visual language that the rest of the app commits to. On scroll, there's no blur — content slides underneath a solid bar.

**Correction:**

```dart
appBar: AppBar(
  backgroundColor: context.bgColor.withValues(alpha: 0.1), // near-transparent
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: true,
  title: Text(
    'Settings',
    style: Theme.of(context).appBarTheme.titleTextStyle,
  ),
  flexibleSpace: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(color: Colors.transparent),
    ),
  ),
),
```

Also add at the top of the file:

```dart
import 'dart:ui';
```

---

### B-3. Missing Folder `android_widgets/` Specified in ARCHITECTURE.md

**Rule violated:** ARCHITECTURE.md — *"`android_widgets/` — Separate Flutter entry point for home_widget"*

**Expected location:** `android_widgets/lib/main.dart` and `android_widgets/lib/counter_widget.dart`

**Actual state:** The folder `android_widgets/` does not exist in the repository. All Android widget code lives inside the main app's `android/` directory (`CounterWidgetProvider.kt`, `WidgetConfigActivity.kt`) — this is the correct approach for Kotlin-side widget implementation, but the Dart-side `home_widget` integration should have a separate entry point per the architecture specification.

**Correction:** Create `android_widgets/lib/main.dart` as a minimal Flutter entry point for the `home_widget` background callback:

```dart
// android_widgets/lib/main.dart
import 'package:home_widget/home_widget.dart';

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) {
  // handle widget tap interactions here if needed
}
```

If the widget only displays data (no interactive taps), a minimal comment file is sufficient:

```dart
// android_widgets/lib/main.dart
// Widget data is sent from the main app via HomeWidget.saveWidgetData().
// No separate Dart entry point is required for display-only widgets.
// See lib/utils/widget_utils.dart for the data-push logic.
```

This satisfies the architecture spec and avoids future confusion.

---

### B-4. `pubspec.yaml` Missing `share_plus` in Locked Package List

**Rule violated:** ARCHITECTURE.md — *"Rule: Do not add packages not in this table without updating this file first."*

**File:** `pubspec.yaml`

**Current state:** `share_plus` is used in `lib/screens/settings/settings_screen.dart` and `lib/sheets/share_sheet.dart`. It is NOT listed in the approved package table in `ARCHITECTURE.md`.

**Evidence:**

```dart
// settings_screen.dart line 3:
import 'package:share_plus/share_plus.dart';
```

**Correction:** Add `share_plus` to the ARCHITECTURE.md package table:

```markdown
| Share | **share_plus ^10.x** | Sharing counter progress cards and app promotion |
```

And confirm the version in `pubspec.yaml` matches. Also update `flutter-skill.md` package version list to include `share_plus`.

---

### B-5. `url_launcher` Is Not Listed in Locked Package Table

**Rule violated:** Same as B-4 — ARCHITECTURE.md package table.

**File:** `pubspec.yaml` / `lib/screens/settings/settings_screen.dart`

`url_launcher` is imported in `settings_screen.dart` and referenced in TASKS.md item `8.2`, but it was never added to the authoritative package table in ARCHITECTURE.md.

**Correction:** Add to ARCHITECTURE.md table:

```markdown
| URL launch | **url_launcher ^6.3.x** | Opening Privacy Policy URL |
```

---

### B-6. `google_fonts` Is Not in pubspec.yaml Despite Font Requirements

**Rule violated:** ARCHITECTURE.md README — *"Premium typography"*; frontend-design skill — *"Avoid generic fonts like Arial and Inter; opt for distinctive choices"*

**Current state:** No font package is listed in `pubspec.yaml`. The app uses the system default (Roboto on Android) via Flutter's implicit fallback. No `fonts:` section in `pubspec.yaml` either.

**Correction:** Add to `pubspec.yaml` dependencies:

```yaml
google_fonts: ^6.2.1
```

And add to ARCHITECTURE.md package table:

```markdown
| Fonts | **google_fonts ^6.2.x** | DM Sans (body) + DM Serif Display (large numbers) |
```

---

### B-7. `flutter_lints` Version Does Not Match TASKS.md Spec

**Rule violated:** TASKS.md `0.3` — specifies `flutter_lints: ^4.0.0`

**File:** `pubspec.yaml` dev_dependencies — verify the actual version matches. If it was scaffolded at `^3.x`, update to `^4.0.0`.

**Correction:**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0   # ensure this matches, not ^3.x
```

---

### B-8. `kDividerColor` Usage Inconsistency

**Rule violated:** CONVENTIONS.md — *"No Hardcoded Values"*; and the `AppColors` extension in `app_theme.dart` which provides `context.dividerColor`.

**Files affected:**

`lib/screens/counters/all_resets_screen.dart` — needs to be checked for any hardcoded `Color(0xFFE5E5EA)` or `kDividerColor` used directly instead of `context.dividerColor`.

`lib/sheets/*.dart` — sheet files may use `kDividerColor` directly instead of `context.dividerColor`.

**General rule to enforce:** Anywhere `kDividerColor` appears directly in a `build()` method outside of `app_theme.dart`, replace with `context.dividerColor`.

**Specific known correct usage:** `counter_detail_screen.dart` correctly uses `context.dividerColor` in dividers. This is the pattern all other files must follow.

---

### B-9. `CountersScreen` `SliverAppBar` `backgroundColor` Is Inconsistent with Spec

**Rule violated:** ARCHITECTURE.md — *"App bar background `kBgColor`"*; TASKS.md `10.12` — *"frosted glass SliverAppBars for main screens"*

**File:** `lib/screens/counters/counters_screen.dart`

**Line:**

```dart
SliverAppBar(
  backgroundColor: context.bgColor.withValues(alpha: 0.1), // ← very low alpha
  ...
  flexibleSpace: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // ← transparent, relies on bgColor alpha above
          ...
        ),
      ),
    ),
  ),
```

At `alpha: 0.1` (10% opacity), the app bar background is nearly invisible. When dark content scrolls under it, the blur works, but the bar's own base tint is wrong — it should be `alpha: 0.75` for light theme and `alpha: 0.80` for dark theme per TASKS.md `10.12` spec.

**Correction:**

```dart
// In counters_screen.dart, SliverAppBar:
backgroundColor: context.bgColor.withValues(alpha: 0.75), // light theme
// For dark theme support, the AppBar's FlexibleSpace Container should carry the color:
child: Container(
  color: context.bgColor.withValues(alpha: 0.80),
),
```

Or alternatively, move the `alpha` logic into the `Container` inside `BackdropFilter` and keep `backgroundColor: Colors.transparent`:

```dart
SliverAppBar(
  backgroundColor: Colors.transparent,   // let flexibleSpace handle it
  flexibleSpace: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: context.bgColor.withValues(alpha: 0.80),
      ),
    ),
  ),
)
```

Apply the same fix to `CalendarScreen` and `CounterDetailScreen` AppBars.

---

### B-10. Version Number in `settings_screen.dart` Is Hardcoded String

**Rule violated:** CONVENTIONS.md version bumping section — *"Version bumps happen in `pubspec.yaml`"*; good practice dictates the version should be read programmatically.

**File:** `lib/screens/settings/settings_screen.dart`

**Line:**

```dart
'Streak Tracker 1.0.0 (build 1)',   // ← hardcoded string literal
```

**Why it matters:** Every time the version is bumped in `pubspec.yaml`, this string must be manually updated too. They will inevitably drift. TASKS.md `11.9` confirms the target version is `1.0.0+1`.

**Correction:** Use `package_info_plus` to read the version dynamically:

Add to `pubspec.yaml`:

```yaml
package_info_plus: ^8.0.0
```

In `settings_screen.dart`, change to a `FutureBuilder` or `ref`-backed provider:

```dart
// Simple FutureBuilder approach:
FutureBuilder<PackageInfo>(
  future: PackageInfo.fromPlatform(),
  builder: (context, snap) {
    final version = snap.data?.version ?? '–';
    final build = snap.data?.buildNumber ?? '–';
    return Text(
      'Streak Tracker $version (build $build)',
      style: TextStyle(color: context.textSecondary, fontSize: 13),
    );
  },
),
```

Add `package_info_plus` to the ARCHITECTURE.md package table as well.

---

### B-11. `CounterCard` `Expanded` Inside Unbounded Context Warning Risk

**Rule violated:** CONVENTIONS.md — *"Build Validation: always run `flutter analyze` after every change — fix all warnings"*

**File:** `lib/widgets/counter_card.dart`

The `Expanded` widget inside `CounterCard`'s `Column` works in the `SliverGrid` context (bounded height = `childAspectRatio: 0.9` × column width) but would cause a `RenderFlex` error if `CounterCard` were ever rendered outside a bounded-height parent (e.g. inside a `Column` with no height constraint). As the codebase grows and `CounterCard` gets reused, this is a latent bug.

**Correction:** Replace `Expanded` with an `AspectRatio` wrapper as documented in `UI_DESIGN_ENHANCEMENT.md` Item 3A. This makes `CounterCard` safe to render in any context.

---

### B-12. TASKS.md Has No Entry for Dark Mode AppBar Blur Inconsistency (Settings)

**Rule violated:** TASKS.md usage — *"Add newly discovered bugs/tasks at the bottom"*

The Settings screen AppBar blur issue (B-2 above) was not caught during Phase 11 testing and is not logged in TASKS.md. Neither is the `EmptyState` dark mode regression (B-1).

**Correction:** Add to TASKS.md Known Issues / Bugs section:

```markdown
- ⬜ `BUG-12` **Settings AppBar missing frosted glass**
  Platform: Both
  Steps: Switch to dark mode → open Settings tab.
  Expected: AppBar blurs content on scroll, consistent with Counters/Calendar.
  Actual: Solid opaque background; no blur.
  Fix: Apply BackdropFilter flexibleSpace pattern to SettingsScreen AppBar.

- ⬜ `BUG-13` **EmptyState text invisible in dark mode**
  Platform: Both
  Steps: Delete all counters → switch to dark mode.
  Expected: "No counters yet" and subtitle text visible in white/light color.
  Actual: Text renders in black (kTextPrimary) on dark background — invisible.
  Fix: Replace `kTextPrimary`/`kTextSecondary` with `context.textPrimary`/`context.textSecondary` in empty_state.dart.
```

---

## Summary Table

| ID | Severity | File | Rule | Status |
| ---- | ---------- | ------ | ------ | -------- |
| B-1 | 🔴 HIGH | `empty_state.dart` | No Hardcoded Values / Dark Mode | Fix immediately |
| B-2 | 🔴 HIGH | `settings_screen.dart` | Frosted glass consistency | Fix immediately |
| B-3 | 🟡 MEDIUM | Missing `android_widgets/` | ARCHITECTURE.md folder structure | Add minimal file |
| B-4 | 🟡 MEDIUM | ARCHITECTURE.md | Package table — `share_plus` unlisted | Update doc |
| B-5 | 🟡 MEDIUM | ARCHITECTURE.md | Package table — `url_launcher` unlisted | Update doc |
| B-6 | 🟡 MEDIUM | `pubspec.yaml` | No font package despite typography spec | Add `google_fonts` |
| B-7 | 🟢 LOW | `pubspec.yaml` | `flutter_lints` version drift | Verify & fix |
| B-8 | 🟡 MEDIUM | Various sheets | `kDividerColor` vs `context.dividerColor` | Audit & fix |
| B-9 | 🔴 HIGH | `counters_screen.dart` | AppBar blur alpha too low (0.1 vs 0.75–0.80) | Fix immediately |
| B-10 | 🟡 MEDIUM | `settings_screen.dart` | Hardcoded version string | Add `package_info_plus` |
| B-11 | 🟢 LOW | `counter_card.dart` | `Expanded` in potentially unbounded context | Refactor to `AspectRatio` |
| B-12 | 🟢 LOW | `TASKS.md` | Missing bug entries for B-1 and B-2 | Update TASKS.md |

---

## Recommended Fix Order

1. **B-1** — `EmptyState` dark mode (30 min, high user-visible impact)
2. **B-9** — AppBar blur alpha on `CountersScreen` (15 min, cosmetic but consistent)
3. **B-2** — Settings frosted glass (20 min, consistency)
4. **B-6** — Add `google_fonts` (1-2 hours, major typographic upgrade)
5. **B-4 + B-5** — Update ARCHITECTURE.md package table (5 min each, documentation)
6. **B-10** — Dynamic version string (30 min, future-proofing)
7. **B-3** — `android_widgets/` stub file (10 min, structure compliance)
8. **B-8** — Audit divider color usage across sheets (30 min, consistency)
9. **B-11** — Refactor `CounterCard` to `AspectRatio` (45 min, robustness)
10. **B-12** — Update TASKS.md with new bug entries (5 min, process)
11. **B-7** — Verify `flutter_lints` version (5 min)
