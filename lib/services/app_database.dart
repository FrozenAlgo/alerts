import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../config/firebase_config.dart';

/// Single RTDB instance — ESP32 and Flutter must use the same database URL.
class AppDatabase {
  AppDatabase._();

  static FirebaseDatabase? _rtdb;

  static FirebaseDatabase get rtdb {
    _rtdb ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: FirebaseConfig.realtimeDatabaseUrl,
    );
    return _rtdb!;
  }

  static Future<void> initialize() async {
    rtdb.setPersistenceEnabled(true);
  }
}
