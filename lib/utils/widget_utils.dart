import '../models/counter.dart';
import 'widget_utils_native.dart'
    if (dart.library.js_interop) 'widget_utils_web.dart' as platform;

Future<void> updateHomeWidgets(List<Counter> counters) =>
    platform.updateHomeWidgets(counters);
