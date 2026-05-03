import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_tracker/constants/app_theme.dart';
import 'package:streak_tracker/widgets/empty_state.dart';

void main() {
  testWidgets('empty state shows copy and fires add callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: EmptyState(onAddCounter: () => tapped = true)),
      ),
    );

    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.text('No counters yet'), findsOneWidget);
    expect(find.text('Tap + to add your first counter'), findsOneWidget);
    expect(find.text('Add Counter'), findsOneWidget);

    await tester.tap(find.text('Add Counter'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
