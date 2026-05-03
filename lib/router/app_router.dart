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
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CountersScreen(),
            transitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: _tabTransitionBuilder,
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CalendarScreen(),
            transitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: _tabTransitionBuilder,
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: _tabTransitionBuilder,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/counters/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: CounterDetailScreen(id: id),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: _slideUpTransitionBuilder,
        );
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

Widget _tabTransitionBuilder(context, animation, secondaryAnimation, child) {
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
}

Widget _slideUpTransitionBuilder(context, animation, secondaryAnimation, child) {
  final slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
  );
  
  final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

  return FadeTransition(
    opacity: fade,
    child: SlideTransition(
      position: slide,
      child: child,
    ),
  );
}

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
