import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/db.dart';
import '../db/db_adapter.dart';

final dbAdapterProvider = Provider<DbAdapter>((ref) => createAdapter());
