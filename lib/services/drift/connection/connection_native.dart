import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import '../../database_service.dart';

/// Native: run the legacy sqflite migration chain (v1→v9) in place, then let
/// Drift adopt the migrated `countscore.db` file directly.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    await DatabaseService.instance.bootstrapMigrate();
    final dir = await getDatabasesPath();
    final file = File(p.join(dir, 'countscore.db'));
    return NativeDatabase.createInBackground(file);
  });
}
