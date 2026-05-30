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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAccentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kAccentBlue.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: kAccentBlue,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No counters yet',
              style: textTheme.titleLarge?.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first counter',
              style: textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddCounter,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Counter',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: kButtonRadius,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
