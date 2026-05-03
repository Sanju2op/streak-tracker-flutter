import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/counter.dart';
import '../utils/share_utils.dart';

class ShareSheet extends StatelessWidget {
  final Counter counter;
  final String period;
  final String? resetMessage;

  const ShareSheet({
    super.key,
    required this.counter,
    required this.period,
    this.resetMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Streak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _ShareOptionTile(
              icon: Icons.square_outlined,
              title: 'Square',
              subtitle: 'Best for posts',
              onTap: () {
                Navigator.pop(context);
                shareCounterImage(context, counter, ShareImageFormat.square, period, resetMessage: resetMessage);
              },
            ),
            const SizedBox(height: 12),
            _ShareOptionTile(
              icon: Icons.crop_portrait,
              title: 'Portrait',
              subtitle: '4:5 ratio',
              onTap: () {
                Navigator.pop(context);
                shareCounterImage(context, counter, ShareImageFormat.portrait, period, resetMessage: resetMessage);
              },
            ),
            const SizedBox(height: 12),
            _ShareOptionTile(
              icon: Icons.smartphone,
              title: 'Story',
              subtitle: 'Full screen 9:16',
              onTap: () {
                Navigator.pop(context);
                shareCounterImage(context, counter, ShareImageFormat.story, period, resetMessage: resetMessage);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bgColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: kAccentBlue, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
