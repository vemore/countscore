// What `ShareResultButton` hands the system share sheet (`systemShareResult`):
// the PNG next to the text, and the text alone when the platform cannot share
// a file — a browser without `navigator.canShare` for files, where share_plus's
// download fallback is off. The screens' share tests are in
// `test/screens/{game_end,ranking,game_analysis}_screen_test.dart`.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:countscore/utils/game_result_share.dart';
import 'package:countscore/widgets/share_result_button.dart';

void main() {
  final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

  /// A share sheet that records every call and — with [refuseFiles] —
  /// throws on a share with files, as share_plus's web plugin does when
  /// `canShare` is false and the download fallback is off.
  Future<ShareResult> Function(ShareParams) sheet(List<ShareParams> calls,
          {bool refuseFiles = false}) =>
      (params) async {
        calls.add(params);
        if (refuseFiles && (params.files?.isNotEmpty ?? false)) {
          throw Exception('Navigator.canShare() is false');
        }
        return const ShareResult('', ShareResultStatus.success);
      };

  test('the PNG goes next to the text, with no download fallback', () async {
    final calls = <ShareParams>[];
    await systemShareResult('1. Dora — 10 points',
        subject: 'Skyjo 3', image: png, sheet: sheet(calls));

    final params = calls.single;
    expect(params.text, '1. Dora — 10 points');
    expect(params.subject, 'Skyjo 3');
    final file = params.files!.single;
    expect(file.mimeType, 'image/png');
    expect(await file.readAsBytes(), png);
    expect(params.fileNameOverrides, [kShareImageName]);
    expect(params.downloadFallbackEnabled, isFalse);
  });

  test('a platform that cannot share the file gets the text alone', () async {
    final calls = <ShareParams>[];
    await systemShareResult('1. Dora — 10 points',
        subject: 'Skyjo 3',
        image: png,
        sheet: sheet(calls, refuseFiles: true));

    expect(calls, hasLength(2));
    final retry = calls.last;
    expect(retry.files, isNull);
    expect(retry.text, '1. Dora — 10 points');
    expect(retry.subject, 'Skyjo 3');
  });

  test('with no image, the text is shared as before', () async {
    final calls = <ShareParams>[];
    await systemShareResult('1. Dora — 10 points', sheet: sheet(calls));

    expect(calls.single.files, isNull);
  });
}
