import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import 'share_utils_native.dart'
    if (dart.library.js_interop) 'share_utils_web.dart';

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
    final valueAndLabel = _primaryValueAndLabel(elapsed, period);

    double width;
    double height;

    switch (format) {
      case ShareImageFormat.square:
        width = 360;
        height = 360;
      case ShareImageFormat.portrait:
        width = 360;
        height = 450;
      case ShareImageFormat.story:
        width = 360;
        height = 640;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            accentColor.withValues(alpha: 0.16),
            const Color(0xFF050505),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          // Minimal top accent strip
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // Streak Title
          Text(
            counter.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Subtitle / Date
          Text(
            'Started on ${formatDate(counter.startedAt)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 32),

          if (resetMessage != null) ...[
            Text(
              resetMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Elegant value display
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${valueAndLabel.$1}',
              style: const TextStyle(
                fontSize: 108,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -4.0,
              ),
            ),
          ),
          
          Text(
            valueAndLabel.$2.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 4.0,
            ),
          ),

          const Spacer(),

          // Minimalist Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'STREAK TRACKER',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          if (format == ShareImageFormat.story)
            const SizedBox(height: 24),
        ],
      ),
    );
  }

  (int, String) _primaryValueAndLabel(ElapsedTime e, String period) {
    switch (period) {
      case 'hours':
        final totalHours =
            ((e.years * 365.25 + e.months * 30.44 + e.days) * 24 + e.hours)
                .round();
        return (totalHours, totalHours == 1 ? 'hour' : 'hours');
      case 'days':
        final totalDays = (e.years * 365.25 + e.months * 30.44 + e.days)
            .round();
        return (totalDays, totalDays == 1 ? 'day' : 'days');
      case 'weeks':
        final totalWeeks = ((e.years * 365.25 + e.months * 30.44 + e.days) / 7)
            .round();
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
  String period, {
  String? resetMessage,
}) async {
  final screenshotController = ScreenshotController();
  final elapsed = getElapsed(
    counter.startedAt,
    DateTime.now().millisecondsSinceEpoch,
  );
  var loaderShown = false;

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  loaderShown = true;

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
      pixelRatio: 3.0,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      loaderShown = false;
    }

    if (kIsWeb) {
      await downloadImageOnWeb(
        imageBytes,
        '${counter.title.replaceAll(' ', '_')}_streak.png',
      );
    } else {
      await shareImageOnNative(
        imageBytes,
        counter.title,
        'My ${counter.title} Streak',
      );
    }
  } catch (e) {
    // Ensure loader is gone on error
    if (context.mounted) {
      if (loaderShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }
}
