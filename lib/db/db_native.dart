import 'db_adapter.dart';
import 'sqflite_adapter.dart';

DbAdapter createPlatformAdapter() => SqfliteAdapter();
