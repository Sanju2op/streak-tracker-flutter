# flutter-skill.md

> Quick-reference skill for AI agents working on Streak Tracker (Flutter).
> Always read ARCHITECTURE.md and TASKS.md alongside this file.
> Repo: https://github.com/Sanju2op/streak-tracker-flutter.git

---

## Session Startup Checklist

1. `Read ARCHITECTURE.md` → understand stack, models, folder structure, UI design spec
2. `Read TASKS.md` → find first `⬜` task in the current phase
3. Open the relevant `UI Images/` file before touching any screen or widget
4. Run `flutter pub get` if `pubspec.yaml` changed
5. Run `flutter analyze` after code changes — fix all warnings before moving on

---

## Package Versions — Pin These

```yaml
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
```

Run `flutter pub outdated` to check for drift — only update with explicit approval.

---

## UI Image → Screen Mapping

| What you're building | Open this image first |
|---|---|
| Counter list (grid) | `UI Images/Counters_Tab.PNG` |
| Counter detail (top) | `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_1.PNG` |
| Counter detail (scrolled, menu + stats) | `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_2_scrolled.PNG` |
| Reset button state | `UI Images/counter_view_clicked_on_counter_detials_of_single_counter_clicked_on_reset_counter_button.PNG` |
| Create/edit sheet | `UI Images/Create-edit_Counters_view_slide_up.PNG` |
| Create/edit filled | `UI Images/create_edit_counters_view_2_filled.PNG` |
| Color picker | `UI Images/Pick_a_color_drawer_view_create-edit_counter_view.PNG` |
| Calendar | `UI Images/Calendar_Tab_1.PNG` |
| Calendar scrolled | `UI Images/Calender_Tab_2.PNG` |
| Filter sheet | `UI Images/Filters_slide_up_View-counters_tab.PNG` |
| Settings | `UI Images/Settings_Tab.PNG` |
| All resets list | `UI Images/from_clicked_on_single_counter_all_resets_button_view.PNG` |
| Stats screen (charts) | `UI Images/concept status after goals button from cllicked on counter view.PNG` |
| Goals screen | `UI Images/concept_Goals_button_from clicked on counter_after_all resets button.PNG` |
| Widget small (2×2) | `UI Images/widget 1 home screen.PNG` |
| Widget medium (4×2) | `UI Images/widget 2 home screen.PNG` |
| Lock screen widget | `UI Images/widget 4  lock screen the rounded area with showing 146 days.PNG` |

---

## Copy-Paste Patterns

### Riverpod AsyncNotifier (counters)

```dart
// lib/providers/counter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/db_provider.dart';
import '../models/counter.dart';
import '../models/reset.dart';
import '../utils/uuid_utils.dart';

final countersNotifierProvider =
    AsyncNotifierProvider<CountersNotifier, List<Counter>>(CountersNotifier.new);

class CountersNotifier extends AsyncNotifier<List<Counter>> {
  @override
  Future<List<Counter>> build() async {
    final db = ref.read(dbAdapterProvider);
    await db.init();
    return db.getCounters();
  }

  Future<void> addCounter(Counter counter) async {
    await ref.read(dbAdapterProvider).insertCounter(counter);
    ref.invalidateSelf();
  }

  Future<void> updateCounter(Counter counter) async {
    await ref.read(dbAdapterProvider).updateCounter(counter);
    ref.invalidateSelf();
  }

  Future<void> deleteCounter(String id) async {
    await ref.read(dbAdapterProvider).deleteCounter(id);
    ref.invalidateSelf();
  }

  Future<void> resetCounter(String id, {String? note, int? resetAt}) async {
    final db = ref.read(dbAdapterProvider);
    final counter = await db.getCounter(id);
    if (counter == null) return;
    final now = resetAt ?? DateTime.now().millisecondsSinceEpoch;
    final reset = Reset(
      id: generateId(),
      counterId: id,
      resetAt: now,
      note: note,
      previousStartedAt: counter.startedAt,
      createdAt: now,
    );
    await db.insertReset(reset);
    await db.updateCounter(counter.copyWith(
      startedAt: now,
      updatedAt: now,
    ));
    ref.invalidateSelf();
  }
}
```

### ConsumerWidget screen (using async provider)

```dart
class CountersScreen extends ConsumerWidget {
  const CountersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countersAsync = ref.watch(countersNotifierProvider);
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(title: const Text('Counters')),
      body: countersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (counters) => counters.isEmpty
            ? const EmptyState()
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.78, // card + label below
                ),
                itemCount: counters.length,
                itemBuilder: (_, i) => CounterCard(counter: counters[i]),
              ),
      ),
    );
  }
}
```

### Opening a bottom sheet

```dart
// Full-height sheet (create/edit)
void _openCreateSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateEditSheet(),
  );
}

// Half-height sheet (reset, color picker, filter)
void _openResetSheet(BuildContext context, Counter counter) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(borderRadius: kSheetRadius),
    builder: (_) => ResetSheet(counter: counter),
  );
}
```

### Live ticking timer (always cancel in dispose)

```dart
class _LiveTimeDisplayState extends State<LiveTimeDisplay> {
  late Timer _timer;
  late ElapsedTime _elapsed;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsed = getElapsed(
        widget.startedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // REQUIRED — memory leak if missing
    super.dispose();
  }
}
```

### Counter card with circle decoration

```dart
class CounterCard extends StatelessWidget {
  final Counter counter;
  const CounterCard({super.key, required this.counter});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(counter.color);
    return GestureDetector(
      onTap: () => context.push('/counters/${counter.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: kCardRadius,
              child: Stack(
                children: [
                  Container(color: color),
                  // translucent circle decoration
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                  // number + unit
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: LiveTimeDisplay(
                      startedAt: counter.startedAt,
                      period: counter.period,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(counter.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(_subtitle(), style: TextStyle(color: kTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
```

### fl_chart bar chart (Stats screen)

```dart
BarChart(
  BarChartData(
    barGroups: buildBarChartData(resets, 'weekly'), // from stats_utils.dart
    borderData: FlBorderData(show: false),
    gridData: const FlGridData(show: true),
    titlesData: FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitle),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
  ),
)
```

### Local notification (Android only)

```dart
// Always gate with kIsWeb check
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> scheduleReminder({
  required String id,
  required String counterTitle,
  required Time time,
  required RepeatInterval repeat,
}) async {
  if (kIsWeb) return; // notifications not supported on web

  const androidDetails = AndroidNotificationDetails(
    'streak_reminders',
    'Streak Reminders',
    importance: Importance.high,
    priority: Priority.high,
  );
  await _plugin.periodicallyShow(
    id.hashCode,
    'Streak Reminder',
    counterTitle,
    repeat,
    const NotificationDetails(android: androidDetails),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}
```

### Platform check

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // web path — shared_preferences, no widgets, no notifications
} else {
  // native path — sqflite, home_widget, flutter_local_notifications
}
```

### Color utilities

```dart
// lib/constants/colors.dart
String colorToHex(Color c) =>
    '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

Color hexToColor(String hex) =>
    Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

Color randomColor() {
  final all = kColorPalettes.values.expand((l) => l).toList();
  return all[Random().nextInt(all.length)];
}
```

---

## Build Commands

```powershell
# Debug APK (no signing needed, for quick testing)
flutter build apk --debug
# → build\app\outputs\flutter-apk\app-debug.apk

# Release APK
flutter build apk --release

# Install on connected device
flutter install

# App Bundle for Play Store
flutter build appbundle --release

# Web — dev
flutter run -d chrome

# Web — production build
flutter build web --web-renderer canvaskit
cd build\web && python -m http.server 8080
```

---

## Common Mistakes — Quick Reference

| ❌ Wrong | ✅ Right |
|---|---|
| Import `sqflite` in a screen | Only in `lib/db/sqflite_adapter.dart` |
| Import `shared_preferences` in a screen | Only in `lib/db/web_adapter.dart` |
| `Navigator.push()` for routed screens | `context.go()` or `context.push()` via go_router |
| Compute elapsed time inline in a widget | Call `getElapsed()` from `time_utils.dart` |
| Store timestamps as `String` | Store as `int` (Unix milliseconds) |
| Forget `_timer.cancel()` in `dispose()` | Always cancel — memory leak otherwise |
| Hardcode `Color(0xFFE63946)` in a widget | Use `hexToColor(counter.color)` |
| `HapticFeedback` guarded by `!kIsWeb` | No guard needed — it's a no-op on web |
| Call `home_widget` API without `!kIsWeb` | Gate ALL `home_widget` calls with `if (!kIsWeb)` |
| Call notification API without `!kIsWeb` | Gate ALL notification calls with `if (!kIsWeb)` |
| `if (!mounted) setState(...)` | Check `if (!mounted) return;` BEFORE `setState` |
| `!` force-unwrap without a comment | Add a comment explaining why it's safe |
| Show lock/premium badge on Goals, Stats, Reminders | No locks — everything is free |
