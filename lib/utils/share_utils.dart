import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../constants/app_theme.dart';
import '../constants/colors.dart';
import '../models/counter.dart';
import '../models/elapsed_time.dart';
import '../utils/time_utils.dart';
import '../utils/format_utils.dart';

enum ShareImageFormat { portrait, square, story }

class ShareImageGenerator extends StatelessWidget {
  final Counter counter;
  final ShareImageFormat format;
  final ElapsedTime elapsed;
  final String period;
  final String? resetMessage;

  const ShareImageGenerator({
    super.key,
    required this.counter,
    required this.format,
    required this.elapsed,
    required this.period,
    this.resetMessage,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = hexToColor(counter.color);

    // Common styling
    const textStyleTitle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    const textStyleSubtitle = TextStyle(
      fontSize: 18,
      color: Colors.white70,
    );

    Widget buildMainContent() {
      final valueAndLabel = _primaryValueAndLabel(elapsed, period);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            counter.title,
            style: textStyleTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (resetMessage != null) ...[
            Text(
              resetMessage!,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 16),
          Text(
            '${valueAndLabel.$1}',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            valueAndLabel.$2.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            resetMessage != null 
                ? 'Streak Tracker App'
                : 'Started ${formatDate(counter.startedAt)}',
            style: textStyleSubtitle,
          ),
        ],
      );
    }

    switch (format) {
      case ShareImageFormat.square:
        return Container(
          width: 1080,
          height: 1080,
          padding: const EdgeInsets.all(60),
          decoration: BoxDecoration(
            color: kBgColor,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(child: buildMainContent()),
          ),
        );
      case ShareImageFormat.portrait:
        return Container(
          width: 1080,
          height: 1350, // 4:5 aspect ratio often used for posts
          padding: const EdgeInsets.all(60),
          decoration: BoxDecoration(
            color: kBgColor,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(child: buildMainContent()),
          ),
        );
      case ShareImageFormat.story:
        return Container(
          width: 1080,
          height: 1920, // 9:16 aspect ratio
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.8),
                accentColor.withValues(alpha: 0.4),
                kBgColor,
              ],
            ),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
              decoration: BoxDecoration(
                color: kCardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: accentColor, width: 4),
              ),
              child: buildMainContent(),
            ),
          ),
        );
    }
  }

  (int, String) _primaryValueAndLabel(ElapsedTime e, String period) {
    switch (period) {
      case 'hours':
        final totalHours = ((e.years * 365.25 + e.months * 30.44 + e.days) * 24 + e.hours).round();
        return (totalHours, totalHours == 1 ? 'hour' : 'hours');
      case 'days':
        final totalDays = (e.years * 365.25 + e.months * 30.44 + e.days).round();
        return (totalDays, totalDays == 1 ? 'day' : 'days');
      case 'weeks':
        final totalWeeks = ((e.years * 365.25 + e.months * 30.44 + e.days) / 7).round();
        return (totalWeeks, totalWeeks == 1 ? 'week' : 'weeks');
      case 'months':
        final totalMonths = e.years * 12 + e.months;
        return (totalMonths, totalMonths == 1 ? 'month' : 'months');
      case 'years':
      default:
        return (e.years, e.years == 1 ? 'year' : 'years');
    }
  }
}

Future<void> shareCounterImage(
  BuildContext context,
  Counter counter,
  ShareImageFormat format,
  String period,
  {String? resetMessage}
) async {
  final screenshotController = ScreenshotController();
  final elapsed = getElapsed(counter.startedAt, DateTime.now().millisecondsSinceEpoch);

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final imageBytes = await screenshotController.captureFromWidget(
      ShareImageGenerator(
        counter: counter,
        format: format,
        elapsed: elapsed,
        period: period,
        resetMessage: resetMessage,
      ),
      delay: const Duration(milliseconds: 100),
      context: context,
    );

    // Hide loading
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/share_${counter.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(imagePath);
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles(
      [XFile(imagePath)],
      text: 'Check out my streak on ${counter.title}!',
    );
  } catch (e) {
    // Hide loading on error
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }
}
