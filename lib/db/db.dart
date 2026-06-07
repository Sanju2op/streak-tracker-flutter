import 'db_adapter.dart';
import 'db_native.dart'
    if (dart.library.js_interop) 'db_web.dart' as platform;

DbAdapter createAdapter() => platform.createPlatformAdapter();
