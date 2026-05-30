# UI Design Enhancement Guide
>
> Streak Tracker Flutter — Applying the frontend-design skill to achieve a cohesive, premium aesthetic

---

## Aesthetic Direction

**Chosen tone:** Refined Minimalist with Depth

This app tracks personal milestones — it should feel *premium, purposeful, and calm*. The design direction is **dark-luxury editorial**: deep surfaces, generous whitespace, sharp typographic hierarchy, and micro-interactions that feel physical. Think of a premium journaling or finance app — not a bright productivity tool.

**What makes it unforgettable:** The frosted-glass card system, where every surface has implied depth. Counter cards glow subtly with their accent color. The timer feels alive — not like a number ticking, but like time moving.

**Key principle:** Every screen must feel like it belongs to the same visual language. Currently the app is inconsistent — this guide fixes that top to bottom.

---

## 1. Typography Overhaul

### Problem

The app has no custom font loaded. It falls back to Android's default Roboto (light mode) or system font — a generic choice that undermines the premium feel described in README.md. The `app_theme.dart` defines text styles with correct sizing and weights but never specifies a typeface.

### Fix: Add Google Fonts

Add `google_fonts` to `pubspec.yaml`:

```yaml
dependencies:
  google_fonts: ^6.2.1
```

Then in `lib/constants/app_theme.dart`, update both `buildLightTheme()` and `buildDarkTheme()` to inject a font pair:

```dart
import 'package:google_fonts/google_fonts.dart';

// Display font: DM Serif Display — sharp, editorial, memorable
// Body font: DM Sans — clean, legible, pairs perfectly
// Why: DM Serif/Sans is a matched pair by the same designer; the serif
// brings character to large numbers and headings while Sans handles body.

ThemeData buildLightTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: kBgColor,
    cardColor: kCardColor,
    dividerColor: kDividerColor,
    colorScheme: const ColorScheme.light(
      primary: kAccentBlue,
      secondary: kAccentBlue,
      surface: kBgColor,
      onSurface: kTextPrimary,
      onSurfaceVariant: kTextSecondary,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      // Large number on cards — use DM Serif for drama
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: -2.0,
        height: 1.0,
      ),
      // Screen titles
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
        letterSpacing: -0.8,
      ),
      // Card section headers
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
        letterSpacing: -0.5,
      ),
      // AppBar title
      titleMedium: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
        letterSpacing: -0.4,
      ),
      // Body text
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: kTextPrimary,
        letterSpacing: -0.3,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: kTextPrimary,
        letterSpacing: -0.2,
      ),
      // Captions and secondary labels
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        color: kTextSecondary,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: kTextPrimary),
      titleTextStyle: GoogleFonts.dmSans(
        color: kTextPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      centerTitle: true,
    ),
    // ... rest of theme unchanged
  );
}
```

Apply same font swap in `buildDarkTheme()` with dark color variants.

### Apply to `LiveTimeDisplay`

In `lib/widgets/live_time_display.dart`, the large card number should use `displayLarge` from the text theme for consistency. Replace the hardcoded `TextStyle` with:

```dart
// Before:
style: const TextStyle(
  color: Colors.white,
  fontSize: 52,
  fontWeight: FontWeight.w900,
  height: 1.0,
  letterSpacing: -2.0,
),

// After:
style: Theme.of(context).textTheme.displayLarge?.copyWith(
  color: Colors.white,
) ?? const TextStyle(color: Colors.white, fontSize: 52),
```

---

## 2. Color System Consistency

### Problem A: Counter Card Shadow Is Clipped

In `lib/widgets/counter_card.dart`, the `BoxShadow` is defined inside the `BoxDecoration` on the inner `Container`, but the parent `ClipRRect` clips everything including the shadow. The shadow never renders.

```dart
// Current — shadow is invisible:
ClipRRect(
  borderRadius: kCardRadius,
  child: Stack(
    children: [
      Container(
        decoration: BoxDecoration(
          gradient: ...,
          boxShadow: [BoxShadow(...)], // ← CLIPPED by ClipRRect above
        ),
      ),
```

**Fix:** Move the shadow to the outer `GestureDetector`'s `Column`, wrapping the card area in a `DecoratedBox` outside the clip:

```dart
GestureDetector(
  onTap: ...,
  child: ScaleTransition(
    scale: _scaleAnimation,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shadow lives OUTSIDE the clip
        Container(
          decoration: BoxDecoration(
            borderRadius: kCardRadius,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: kCardRadius,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(children: [...]),
            ),
          ),
        ),
        // Labels below card unchanged
      ],
    ),
  ),
)
```

### Problem B: Gradient End Color Transparency

The card gradient ends at `color.withValues(alpha: 0.8)` — on darker accent colors (e.g. dark navy, forest green from Landscapes palette) this creates an ugly semi-transparent edge. Instead, darken the color mathematically:

```dart
// Before:
colors: [color, color.withValues(alpha: 0.8)],

// After — creates a proper darker tint without transparency:
colors: [
  color,
  HSLColor.fromColor(color)
    .withLightness(
      (HSLColor.fromColor(color).lightness - 0.10).clamp(0.0, 1.0)
    )
    .toColor(),
],
```

### Problem C: Bottom Navigation Bar Lacks Visual Consistency

The bottom nav uses plain `Colors.white` (light) and `Color(0xFF121212)` (dark) with no frosted glass, while the app bars have beautiful blur. This creates a jarring discontinuity at the bottom of every screen.

**Fix:** Add a frosted glass bottom nav wrapper. In the `ScaffoldWithNavBar` widget (in `lib/router/app_router.dart`), wrap the `BottomNavigationBar` in a `ClipRect` + `BackdropFilter`:

```dart
bottomNavigationBar: ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        color: context.bgColor.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent, // ← important
        elevation: 0,                        // ← remove double shadow
        // ... rest unchanged
      ),
    ),
  ),
),
```

Add `import 'dart:ui';` to the file if not already present.

### Problem D: Dark Theme Bottom Nav Color Is Not a Named Constant

`Color(0xFF121212)` in `buildDarkTheme()` is hardcoded inline — violates the "No Hardcoded Values" rule and makes it impossible to update consistently. Add to `app_theme.dart`:

```dart
const kNavBarColorDark = Color(0xFF0A0A0A); // slightly deeper than card for depth
```

Then reference it in `buildDarkTheme()`:

```dart
bottomNavigationBarTheme: const BottomNavigationBarThemeData(
  backgroundColor: kNavBarColorDark,
  ...
),
```

---

## 3. Spatial Composition & Layout Fixes

### Problem A: Counter Card `Expanded` Widget Structure

The `CounterCard` uses `Expanded` inside a `Column` which is inside a `GestureDetector`. The `Expanded` widget only works when the parent `Column` has bounded height — in `SliverGrid` with `childAspectRatio: 0.9`, height is bounded by the grid cell, which works. However, the structure mixes `Expanded` (for the card) with `Text` widgets below (for title and subtitle) inside the same `Column`. This means the card doesn't have a guaranteed 1:1 aspect ratio.

**Fix:** Use the `AspectRatio` wrapper correctly — restructure so the card portion always has a defined size:

```dart
// Replace Expanded with AspectRatio for the card portion:
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      decoration: BoxDecoration(
        borderRadius: kCardRadius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: kCardRadius,
        child: AspectRatio(
          aspectRatio: 1.0, // forces square card
          child: Stack(children: [/* gradient + circle + LiveTimeDisplay */]),
        ),
      ),
    ),
    const SizedBox(height: 8),
    Text(title, ...),
    Text(subtitle, ...),
  ],
)
```

The `SliverGrid` `childAspectRatio` should be reduced to around `0.78` to account for the two text lines below the square card.

### Problem B: InkWell Ripple Overflow on Menu Rows

In `_MenuRow` (`counter_detail_screen.dart`), the `InkWell` has `borderRadius: BorderRadius.circular(12)` but the parent card's `Container` uses `kCardRadius` (16px). The ripple can visually overflow the card's rounded corners at the top and bottom rows.

**Fix:** Wrap the entire `_MenuListCard` content in `ClipRRect(borderRadius: kCardRadius)` so ink splashes are clipped to the card shape:

```dart
// In _MenuListCard.build():
Container(
  decoration: BoxDecoration(
    color: context.cardColor,
    borderRadius: kCardRadius,
  ),
  child: ClipRRect(          // ← ADD THIS
    borderRadius: kCardRadius,
    child: Column(
      children: [
        _MenuRow(...),
        Divider(...),
        // ...
      ],
    ),
  ),
),
```

### Problem C: Settings Screen AppBar Lacks Blur

The `SettingsScreen` uses a plain `AppBar` with `backgroundColor: context.bgColor` — a solid color. Every other screen (Counters, CounterDetail) uses the frosted glass blur pattern. This looks jarring on the Settings tab.

**Fix:** Replace the Settings `AppBar` with the same frosted glass pattern:

```dart
// In settings_screen.dart:
appBar: AppBar(
  backgroundColor: context.bgColor.withValues(alpha: 0.1),
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

Add `import 'dart:ui';` to `settings_screen.dart`.

---

## 4. EmptyState Visual Enhancement

### Problem

The current `EmptyState` widget is functional but generic — a timer icon, two text lines, and an outlined button. It uses hardcoded `kTextPrimary` constants (not `context.textPrimary`) which breaks dark mode. It also misses an opportunity to be memorable.

### Fix: Dark Mode Colors + Visual Polish

First, fix the hardcoded constants in `lib/widgets/empty_state.dart`:

```dart
// Before:
style: textTheme.titleLarge?.copyWith(
  color: kTextPrimary,            // ← BREAKS dark mode
  fontWeight: FontWeight.w700,
),

// After:
style: textTheme.titleLarge?.copyWith(
  color: context.textPrimary,     // ← theme-aware
  fontWeight: FontWeight.w700,
),
```

```dart
// Before:
style: textTheme.bodyMedium?.copyWith(color: kTextSecondary),

// After:
style: textTheme.bodyMedium?.copyWith(color: context.textSecondary),
```

Then enhance the visual design of the empty state:

```dart
// Replace the plain icon with a styled container:
Container(
  width: 96,
  height: 96,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: kAccentBlue.withValues(alpha: 0.10),
    border: Border.all(
      color: kAccentBlue.withValues(alpha: 0.20),
      width: 1.5,
    ),
  ),
  child: const Icon(
    Icons.timer_outlined,
    color: kAccentBlue,
    size: 44,
  ),
),
const SizedBox(height: 24),
// ... text lines unchanged ...
const SizedBox(height: 28),
// Replace OutlinedButton with a filled accent button for more visual weight:
ElevatedButton.icon(
  onPressed: onAddCounter,
  icon: const Icon(Icons.add, size: 18),
  label: const Text('Add Counter'),
  style: ElevatedButton.styleFrom(
    backgroundColor: kAccentBlue,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    elevation: 0,
  ),
),
```

---

## 5. Counter Card Circle Decoration Enhancement

The current white circle at bottom-right of counter cards has `opacity: 0.12` — barely visible. The design reference (`UI Images/Counters_Tab.PNG`) shows a much more prominent circle that adds real depth.

**Enhancement:** Add a second, smaller inner circle to create a layered bubble effect:

```dart
// In counter_card.dart Stack children, replace single circle with two:

// Outer large circle — keeps current position
Positioned(
  right: -30,
  bottom: -20,
  child: Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.12),
    ),
  ),
),
// Inner smaller circle — higher opacity, creates depth
Positioned(
  right: -10,
  bottom: 10,
  child: Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.08),
    ),
  ),
),
```

---

## 6. Stats Summary Card Visual Hierarchy

### Problem

The `StatsSummaryCard` shows 4 stats in a flat 2×2 grid with no visual differentiation. The "Resets" number gets the same treatment as "Longest Streak" — but Resets (an integer) will be formatted as `"3"` while streaks are formatted as `"27 years"` — very different visual weights.

### Enhancement: Add subtle dividers and improve cell spacing

```dart
// Replace the current Row layout with a proper 2×2 grid with dividers:

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Stats', style: ...),
    const SizedBox(height: 16),
    IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '${stats.resetCount}',
              label: 'Resets',
              isHighlight: false,
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: context.dividerColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _StatCell(
                value: _formatDays(stats.daysSinceStart, period),
                label: 'Since started',
                isHighlight: false,
              ),
            ),
          ),
        ],
      ),
    ),
    Divider(height: 32, thickness: 1, color: context.dividerColor),
    IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: _formatDays(stats.longestStreakDays, period),
              label: 'Longest Streak',
              isHighlight: true,
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: context.dividerColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _StatCell(
                value: _formatDays(stats.averageStreakDays, period),
                label: 'Average Streak',
                isHighlight: false,
              ),
            ),
          ),
        ],
      ),
    ),
  ],
)
```

---

## 7. Staggered Animation Cap

In `lib/screens/counters/counters_screen.dart`, the stagger animation currently delays all cards linearly (`index * 0.05`). For large lists (10+ counters), cards at the end have an `end` value of `0.55+` — meaning they barely animate before the controller completes.

**Fix:** Cap the stagger at 6 items as specified in TASKS.md `10.10`:

```dart
// In _CounterGridState build():
final start = (index * 0.05).clamp(0.0, 0.30); // cap start at 30%
final end = (start + 0.40).clamp(0.0, 1.0);

// Cards beyond index 6 will all start at 0.30 and end at 0.70 — they
// still animate in but without the excessively delayed stagger
```

---

## 8. Sort Dialog Visual Consistency

The sort dialog in `counters_screen.dart` uses `container.cardColor.withValues(alpha: 0.9)` — good. But the `transitionBuilder` applies `BackdropFilter` on the entire screen area during transition. This causes a performance hitch on lower-end devices.

**Enhancement:** Pre-render the blur as a separate `Opacity`-animated background instead:

```dart
transitionBuilder: (ctx, anim1, anim2, child) {
  return Stack(
    children: [
      // Blurred background — static after threshold to reduce repaints
      if (anim1.value > 0.1)
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0,  // reduced from 12 for performance
            sigmaY: 8.0,
          ),
          child: Container(color: Colors.transparent),
        ),
      FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
    ],
  );
},
```

---

## 9. Calendar Screen Bottom Panel Enhancement

The calendar screen bottom panel (white card with rounded top corners) currently uses `kSheetRadius` for border radius. However the Calendar body is a `Column` inside a `Scaffold` — if the calendar takes most of the screen height, the panel might sit at different heights depending on device size.

**Enhancement:** Pin the panel to a consistent height of `40%` of the screen using `SizedBox` + `Expanded`:

```dart
// In calendar_screen.dart body Column:
Expanded(
  flex: 3,
  child: TableCalendar(...),
),
Expanded(
  flex: 2,  // always takes ~40% of body height
  child: Container(
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: kSheetRadius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: _DayPanel(...),
  ),
),
```

---

## 10. Create/Edit Sheet Preview Card

The preview card in the `CreateEditSheet` shows `0 Days / 0 Hours / 0 Minutes / 0 Seconds` when creating. The design reference shows this as a full-width colored card.

**Enhancement:** Make the 4 columns in the preview card match the typographic style of the counter cards — white numbers with the display font:

```dart
// In create_edit_sheet.dart preview card, for each column:
Text(
  '$value',
  style: GoogleFonts.dmSerifDisplay(
    color: Colors.white,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.0,
  ),
),
Text(
  label,
  style: TextStyle(
    color: Colors.white.withValues(alpha: 0.7),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  ),
),
```

---

## 11. Consistent Border Radius Token

Currently the codebase uses:

- `kCardRadius` = `BorderRadius.all(Radius.circular(16))` — cards
- `kSheetRadius` = `BorderRadius.vertical(top: Radius.circular(20))` — sheets
- `BorderRadius.circular(12)` — buttons, hardcoded in multiple places
- `BorderRadius.circular(8)` — inner containers, hardcoded
- `BorderRadius.circular(28)` — sort dialog, hardcoded

**Fix:** Add these additional named constants to `app_theme.dart`:

```dart
const kButtonRadius = BorderRadius.all(Radius.circular(12));
const kInnerRadius = BorderRadius.all(Radius.circular(8));
const kDialogRadius = BorderRadius.all(Radius.circular(28));
const kIconRadius = BorderRadius.all(Radius.circular(8));   // menu icon bg
const kPillRadius = BorderRadius.all(Radius.circular(100)); // buttons like Share
```

Then do a project-wide find-and-replace to use these tokens everywhere.

**Specific locations to update:**

- `counter_detail_screen.dart` line with `BorderRadius.circular(12)` on Reset button → `kButtonRadius`
- `counter_detail_screen.dart` `BorderRadius.circular(8)` on icon backgrounds → `kIconRadius`
- `counters_screen.dart` `BorderRadius.circular(28)` on sort dialog → `kDialogRadius`
- `empty_state.dart` `BorderRadius.circular(12)` on Add Counter button → `kButtonRadius`
- `time_tab_selector.dart` `BorderRadius.circular(8)` on tab container → `kInnerRadius`
- `time_tab_selector.dart` `BorderRadius.circular(6)` on active tab → use `kInnerRadius` or a new `kTabRadius = BorderRadius.circular(6)` const

---

## 12. Motion: Add Fade to CounterDetail Menu Rows on Load

The `CounterDetailScreen` body loads instantly (no stagger). The menu rows could benefit from a simple staggered fade-in after navigation:

```dart
// Wrap _MenuListCard and StatsSummaryCard in a delayed AnimatedOpacity
// using TickerProviderStateMixin already on _CounterDetailScreenState:

AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: _contentVisible ? 1.0 : 0.0,
  child: _MenuListCard(counterId: counter.id, accentColor: accentColor),
),
```

Toggle `_contentVisible` to `true` in a `WidgetsBinding.instance.addPostFrameCallback` in `initState`.

---

## Summary Checklist

| # | Change | File(s) | Priority |
|---|--------|---------|----------|
| 1 | Add `google_fonts` (DM Sans + DM Serif Display) | `pubspec.yaml`, `app_theme.dart`, `live_time_display.dart` | HIGH |
| 2 | Fix card shadow clipping — move outside `ClipRRect` | `counter_card.dart` | HIGH |
| 3 | Fix gradient end-color transparency on dark accents | `counter_card.dart` | MEDIUM |
| 4 | Frosted glass on `BottomNavigationBar` | `app_router.dart` (ScaffoldWithNavBar) | HIGH |
| 5 | Add `kNavBarColorDark` constant | `app_theme.dart` | LOW |
| 6 | Fix `InkWell` ripple overflow in menu card | `counter_detail_screen.dart` | MEDIUM |
| 7 | Frosted glass `AppBar` on Settings screen | `settings_screen.dart` | HIGH |
| 8 | Fix `EmptyState` hardcoded `kTextPrimary`/`kTextSecondary` | `empty_state.dart` | HIGH |
| 9 | Enhance `EmptyState` visual (icon ring, filled button) | `empty_state.dart` | MEDIUM |
| 10 | Layered circle decoration on counter cards | `counter_card.dart` | LOW |
| 11 | Stats card vertical dividers + `IntrinsicHeight` rows | `stats_summary_card.dart` | MEDIUM |
| 12 | Cap stagger animation at 6 items | `counters_screen.dart` | MEDIUM |
| 13 | Reduce blur sigma in sort dialog transition | `counters_screen.dart` | LOW |
| 14 | Calendar panel at consistent 40% height | `calendar_screen.dart` | MEDIUM |
| 15 | Add border radius token constants | `app_theme.dart` + all screens | MEDIUM |
| 16 | Staggered fade-in on CounterDetail body sections | `counter_detail_screen.dart` | LOW |
