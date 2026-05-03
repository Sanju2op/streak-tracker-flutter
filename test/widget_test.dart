import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/app.dart';
import 'package:streak_tracker/router/app_router.dart';

void main() {
  testWidgets('tab shell switches between primary screens', (tester) async {
    await tester.pumpWidget(const StreakTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Counters'), findsWidgets);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);

    appRouter.go('/counters');
    await tester.pumpAndSettle();
    appRouter.push('/counters/demo-counter');
    await tester.pumpAndSettle();

    expect(find.text('Counter Detail'), findsOneWidget);
    expect(find.text('Counter Detail: demo-counter'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Counters'), findsWidgets);
  });
}
