import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

class ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: kAccentBlue,
                side: const BorderSide(color: kAccentBlue),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
