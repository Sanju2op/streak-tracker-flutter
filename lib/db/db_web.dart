import 'db_adapter.dart';
import 'web_adapter.dart';

DbAdapter createPlatformAdapter() => WebAdapter();
