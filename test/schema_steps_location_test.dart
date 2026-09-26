// Where the shared schema steps live: one engine-neutral file outside the
// sync layer, the one the db-migration skill names. A step written anywhere
// else splits the chain across files again, or drags a data-only step into
// `lib/services/sync/` (and so into lane C).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _stepsFile = 'lib/services/schema_steps.dart';

void main() {
  final definition = RegExp(r'^Future<void> (applyV\d+)\(', multiLine: true);

  test('every applyVN is defined in lib/services/schema_steps.dart', () {
    final found = <String, String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      for (final m in definition.allMatches(entity.readAsStringSync())) {
        found[m.group(1)!] = path;
      }
    }
    expect(found.keys, containsAll([for (var v = 12; v <= 21; v++) 'applyV$v']));
    for (final entry in found.entries) {
      expect(entry.value, _stepsFile, reason: entry.key);
    }
    expect(_stepsFile, isNot(startsWith('lib/services/sync/')));
  });

  test('sync_schema.dart keeps only the sync bookkeeping', () {
    final source = File('lib/services/sync/sync_schema.dart').readAsStringSync();
    expect(definition.hasMatch(source), isFalse);
    expect(source, contains('Future<void> applySyncV10('));
    expect(source, contains('final syncV11Statements'));
  });

  test('the db-migration skill names schema_steps.dart for a new step', () {
    final skill = File('.claude/skills/db-migration/SKILL.md').readAsStringSync();
    expect(skill, contains('`$_stepsFile`'));
  });

  test('both upgrade paths import the steps from schema_steps.dart', () {
    expect(File('lib/services/database_service.dart').readAsStringSync(),
        contains("import 'schema_steps.dart';"));
    expect(File('lib/services/drift/database.dart').readAsStringSync(),
        contains("import '../schema_steps.dart';"));
    expect(File('lib/services/drift/schema_v20.dart').existsSync(), isFalse);
  });
}
