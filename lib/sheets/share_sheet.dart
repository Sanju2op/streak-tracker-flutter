import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../constants/app_theme.dart';
import '../models/counter.dart';
import '../utils/share_utils.dart';
import '../utils/time_utils.dart';

class ShareSheet extends StatefulWidget {
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
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  ShareImageFormat _selectedFormat = ShareImageFormat.portrait;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: kAccentBlue, fontSize: 17),
                  ),
                ),
                const SizedBox(
                  width: 48,
                ), // Placeholder to keep Share button on the right
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final rootContext = Navigator.of(
                      context,
                      rootNavigator: true,
                    ).context;
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      shareCounterImage(
                        rootContext,
                        widget.counter,
                        _selectedFormat,
                        widget.period,
                        resetMessage: widget.resetMessage,
                      );
                    });
                  },
                  child: const Text(
                    kIsWeb ? 'Download' : 'Share',
                    style: TextStyle(
                      color: kAccentBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select size',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Preview different sizes for different kinds of social media',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Format Selector Icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _FormatIcon(
                          format: ShareImageFormat.square,
                          isSelected:
                              _selectedFormat == ShareImageFormat.square,
                          onTap: () => setState(
                            () => _selectedFormat = ShareImageFormat.square,
                          ),
                          label: 'Square',
                        ),
                        _FormatIcon(
                          format: ShareImageFormat.portrait,
                          isSelected:
                              _selectedFormat == ShareImageFormat.portrait,
                          onTap: () => setState(
                            () => _selectedFormat = ShareImageFormat.portrait,
                          ),
                          label: 'Portrait',
                        ),
                        _FormatIcon(
                          format: ShareImageFormat.story,
                          isSelected:
                              _selectedFormat == ShareImageFormat.story,
                          onTap: () => setState(
                            () => _selectedFormat = ShareImageFormat.story,
                          ),
                          label: 'Story',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Preview Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 360,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: ShareImageGenerator(
                          counter: widget.counter,
                          format: _selectedFormat,
                          elapsed: getElapsed(
                            widget.counter.startedAt,
                            DateTime.now().millisecondsSinceEpoch,
                          ),
                          period: widget.period,
                          resetMessage: widget.resetMessage,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatIcon extends StatelessWidget {
  final ShareImageFormat format;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const _FormatIcon({
    required this.format,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (format) {
      case ShareImageFormat.square:
        icon = Icons.square_outlined;
      case ShareImageFormat.portrait:
        icon = Icons.crop_portrait;
      case ShareImageFormat.story:
        icon = Icons.smartphone;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: isSelected ? context.cardColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? kAccentBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? kAccentBlue : context.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? context.textPrimary : context.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? kAccentBlue
                    : context.textSecondary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              color: isSelected ? kAccentBlue : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}
