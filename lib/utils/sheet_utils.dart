import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool fullHeight = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: fullHeight,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _BlurSheetWrapper(fullHeight: fullHeight, child: child),
  );
}

class _BlurSheetWrapper extends StatelessWidget {
  final Widget child;
  final bool fullHeight;

  const _BlurSheetWrapper({
    required this.child,
    this.fullHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor.withValues(alpha: 0.92),
          borderRadius: kSheetRadius,
        ),
        child: child,
      ),
    );
  }
}
