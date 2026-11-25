// The integration-test driver, keeping the screenshots a test takes
// (`IntegrationTestWidgetsFlutterBinding.takeScreenshot`) as PNG files under
// $SCREENSHOT_DIR, or build/screenshots. Used by the multi-group e2e run with
// --dart-define=SCREENSHOTS=true (.llmwiki/Testing.md).

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final dir = Directory(Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots')
          ..createSync(recursive: true);
        File('${dir.path}/$name.png').writeAsBytesSync(bytes);
        return true;
      },
    );
