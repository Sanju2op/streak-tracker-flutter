import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/counter.dart';

Future<void> updateHomeWidgets(List<Counter> counters) async {
  try {
    final data = counters.take(4).map((c) => c.toMap()).toList();
    await HomeWidget.saveWidgetData<String>('counters_json', jsonEncode(data));
    await HomeWidget.updateWidget(name: 'CounterWidgetProvider');
    await HomeWidget.updateWidget(name: 'CounterWidgetProviderMedium');
    await HomeWidget.updateWidget(name: 'CounterWidgetProviderRounded');
    await HomeWidget.updateWidget(name: 'CounterWidgetProviderLock');
  } catch (e) {
    debugPrint('Error updating home widgets: $e');
  }
}
