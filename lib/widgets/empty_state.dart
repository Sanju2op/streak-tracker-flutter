import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAddCounter;

  const EmptyState({super.key, required this.onAddCounter});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: kAccentBlue, size: 64),
            const SizedBox(height: 18),
            Text(
              'No counters yet',
              style: textTheme.titleLarge?.copyWith(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first counter',
              style: textTheme.bodyMedium?.copyWith(color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            OutlinedButton(
              onPressed: onAddCounter,
              style: OutlinedButton.styleFrom(
                foregroundColor: kAccentBlue,
                side: const BorderSide(color: kAccentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Add Counter',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
