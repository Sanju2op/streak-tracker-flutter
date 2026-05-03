import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_theme.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/counters/all_resets_screen.dart';
import '../screens/counters/counter_detail_screen.dart';
import '../screens/counters/counters_screen.dart';
import '../screens/counters/goals_screen.dart';
import '../screens/counters/reminders_screen.dart';
import '../screens/counters/stats_screen.dart';
import '../screens/settings/settings_screen.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/counters',
          builder: (context, state) => const CountersScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/counters/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CounterDetailScreen(id: id);
      },
      routes: [
        GoRoute(
          path: 'resets',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return AllResetsScreen(counterId: id);
          },
        ),
        GoRoute(
          path: 'goals',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return GoalsScreen(counterId: id);
          },
        ),
        GoRoute(
          path: 'stats',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return StatsScreen(counterId: id);
          },
        ),
        GoRoute(
          path: 'reminders',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return RemindersScreen(counterId: id);
          },
        ),
      ],
    ),
  ],
  redirect: (context, state) => state.uri.path == '/' ? '/counters' : null,
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = _indexForPath(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: kCardColor,
          border: Border(top: BorderSide(color: kDividerColor, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_pathForIndex(index)),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Counters',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  int _indexForPath(String path) {
    if (path.startsWith('/calendar')) return 1;
    if (path.startsWith('/settings')) return 2;
    return 0;
  }

  String _pathForIndex(int index) {
    return switch (index) {
      1 => '/calendar',
      2 => '/settings',
      _ => '/counters',
    };
  }
}
