import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_theme.dart';
import 'router/app_router.dart';
import 'providers/goal_achievement_service.dart';
import 'providers/theme_provider.dart';

class StreakTrackerApp extends ConsumerWidget {
  const StreakTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instantiate the goal achievement service so it stays alive
    ref.watch(goalAchievementServiceProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Streak Tracker',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
