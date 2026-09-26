// Where the shared schema steps live: one engine-neutral file outside the
// sync layer, the one the db-migration skill names. A step written anywhere
// else splits the chain across files again, or drags a data-only step into
// `lib/services/sync/` (and so into lane C).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _stepsFile = 'lib/services/schema_steps.dart';

/// A top-level `Future applyVN(` or `Future<void> applyVN(`.
final _definition =
    RegExp(r'^Future(<void>)?\s+(applyV\d+)\s*\(', multiLine: true);

/// An import of schema_steps.dart, relative or `package:`.
final _importsSteps = RegExp(r'''^import\s+['"][^'"]*schema_steps\.dart['"]''',
    multiLine: true);

void main() {
  test('every applyVN is defined once, in lib/services/schema_steps.dart', () {
    final definitions = <(String, String)>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      for (final m in _definition.allMatches(entity.readAsStringSync())) {
        definitions.add((m.group(2)!, path));
      }
    }
    final names = [for (final (name, _) in definitions) name];
    for (var v = 12; v <= 21; v++) {
      expect(names.where((n) => n == 'applyV$v'), hasLength(1),
          reason: 'applyV$v must be defined exactly once');
    }
    for (final (name, path) in definitions) {
      expect(path, _stepsFile, reason: name);
    }
  });

  test('sync_schema.dart keeps only the sync bookkeeping', () {
    final source =
        File('lib/services/sync/sync_schema.dart').readAsStringSync();
    expect(_definition.hasMatch(source), isFalse);
    expect(source, contains('Future<void> applySyncV10('));
    expect(source, contains('final syncV11Statements'));
  });

  test('the db-migration skill names schema_steps.dart for a new step', () {
    final skill =
        File('.claude/skills/db-migration/SKILL.md').readAsStringSync();
    expect(skill, contains('`$_stepsFile`'));
  });

  test('both upgrade paths import the steps from schema_steps.dart', () {
    for (final path in [
      'lib/services/database_service.dart',
      'lib/services/drift/database.dart',
    ]) {
      expect(_importsSteps.hasMatch(File(path).readAsStringSync()), isTrue,
          reason: path);
    }
    expect(File('lib/services/drift/schema_v20.dart').existsSync(), isFalse);
  });
}
