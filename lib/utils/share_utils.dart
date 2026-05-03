import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../constants/colors.dart';
import '../models/counter.dart';
import '../models/elapsed_time.dart';
import '../utils/time_utils.dart';
import '../utils/format_utils.dart';

enum ShareImageFormat { portrait, square, story }

class ChevronPainter extends CustomPainter {
  final Color color;
  ChevronPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const int count = 6;
    const double spacing = 25.0;
    const double width = 250.0;
    const double height = 100.0;

    for (int i = 0; i < count; i++) {
      final path = Path();
      final double yOffset = i * spacing;
      path.moveTo(0, yOffset + height);
      path.lineTo(width / 2, yOffset);
      path.lineTo(width, yOffset + height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
    const backgroundColor = Color(0xFF1C1C1E);

    Widget buildChevronPattern() {
      return Positioned(
        left: -50,
        top: 40,
        child: Transform.rotate(
          angle: -0.1,
          child: CustomPaint(
            size: const Size(300, 300),
            painter: ChevronPainter(color: accentColor.withValues(alpha: 0.8)),
          ),
        ),
      );
    }

    Widget buildMainContent() {
      final valueAndLabel = _primaryValueAndLabel(elapsed, period);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Text(
            counter.title,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Started on ${formatDate(counter.startedAt)}',
            style: TextStyle(
              fontSize: 22,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 80),
          if (resetMessage != null) ...[
            Text(
              resetMessage!,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${valueAndLabel.$1}',
              style: const TextStyle(
                fontSize: 280,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            valueAndLabel.$2.toUpperCase(),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 12,
            ),
          ),
        ],
      );
    }

    Widget buildBranding() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: backgroundColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracked with',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Days Since',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      );
    }

    double width;
    double height;

    switch (format) {
      case ShareImageFormat.square:
        width = 1080;
        height = 1080;
      case ShareImageFormat.portrait:
        width = 1080;
        height = 1350;
      case ShareImageFormat.story:
        width = 1080;
        height = 1920;
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Stack(
        children: [
          buildChevronPattern(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: buildMainContent(),
            ),
          ),
          Positioned(
            bottom: format == ShareImageFormat.story ? 120 : 80,
            left: 80,
            child: buildBranding(),
          ),
        ],
      ),
    );
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
      subject: 'My ${counter.title} Streak',
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
