import 'package:flutter/material.dart';

import 'constants/app_theme.dart';
import 'router/app_router.dart';

class StreakTrackerApp extends StatelessWidget {
  const StreakTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Streak Tracker',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
