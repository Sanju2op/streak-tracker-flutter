import 'package:flutter/foundation.dart' show kIsWeb;

import 'db_adapter.dart';
import 'sqflite_adapter.dart';
import 'web_adapter.dart';

DbAdapter createAdapter() => kIsWeb ? WebAdapter() : SqfliteAdapter();
