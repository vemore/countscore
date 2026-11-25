// SecureSyncCredentials: one pair of tokens per group, keyed by group id since
// schema v23, and the single pair an older version stored under two fixed keys
// (`sync.deviceToken`, `sync.shareToken`) moved on first read, then deleted.
// The same code runs on Android (Keystore) and on the web (encrypted
// localStorage): flutter_secure_storage's test platform stands in for both.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/services/sync/sync_credentials.dart';

const _a = 'aaaaaaaa-1111-4111-8111-111111111111';
const _b = 'bbbbbbbb-1111-4111-8111-111111111111';

Future<Map<String, String>> _stored() => const FlutterSecureStorage().readAll();

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('each group keeps its own pair', () async {
    final credentials = SecureSyncCredentials();
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');
    await credentials.save(_b, deviceToken: 'device-b', shareToken: 'share-b');
    await credentials.saveShareToken(_b, 'share-b2');

    expect(await credentials.deviceToken(_a), 'device-a');
    expect(await credentials.shareToken(_a), 'share-a');
    expect(await credentials.deviceToken(_b), 'device-b');
    expect(await credentials.shareToken(_b), 'share-b2');
    expect(await credentials.groupIds(), {_a, _b});

    await credentials.clear(_a);
    expect(await credentials.deviceToken(_a), isNull);
    expect(await credentials.shareToken(_a), isNull);
    expect(await credentials.deviceToken(_b), 'device-b');
    expect(await credentials.groupIds(), {_b});
  });

  test('the pre-v23 pair is moved under the first group read, then deleted', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSyncCredentials.legacyDeviceTokenKey: 'device-old',
      SecureSyncCredentials.legacyShareTokenKey: 'share-old',
    });
    final credentials = SecureSyncCredentials();

    expect(await credentials.deviceToken(_a), 'device-old');

    expect(await _stored(), {
      SecureSyncCredentials.deviceTokenKey(_a): 'device-old',
      SecureSyncCredentials.shareTokenKey(_a): 'share-old',
      SecureSyncCredentials.uncheckedKey(_a): '1',
    });
    expect(await credentials.shareToken(_a), 'share-old');
    expect(await credentials.deviceToken(_b), isNull, reason: 'claimed once, by one group');
  });

  test('a pair moved from the pre-v23 keys needs a group check, until it is marked', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSyncCredentials.legacyDeviceTokenKey: 'device-old',
      SecureSyncCredentials.legacyShareTokenKey: 'share-old',
    });
    final credentials = SecureSyncCredentials();
    await credentials.save(_b, deviceToken: 'device-b', shareToken: 'share-b');

    expect(await credentials.deviceToken(_a), 'device-old');
    expect(await credentials.needsGroupCheck(_a), isTrue, reason: 'the old pair names no group');
    expect(await credentials.needsGroupCheck(_b), isFalse, reason: 'saved by a join');

    await credentials.markGroupChecked(_a);
    expect(await credentials.needsGroupCheck(_a), isFalse);
    expect(await credentials.groupIds(), {_a, _b});
  });

  test('clearing a group drops its unchecked flag with its pair', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSyncCredentials.legacyDeviceTokenKey: 'device-old',
    });
    final credentials = SecureSyncCredentials();
    await credentials.deviceToken(_a);

    await credentials.clear(_a);

    expect(await _stored(), isEmpty);
  });

  test('a group that already has a pair keeps it; the legacy one is dropped', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSyncCredentials.legacyDeviceTokenKey: 'device-old',
      SecureSyncCredentials.legacyShareTokenKey: 'share-old',
      SecureSyncCredentials.deviceTokenKey(_a): 'device-a',
    });
    final credentials = SecureSyncCredentials();

    expect(await credentials.shareToken(_a), isNull);
    expect(await credentials.deviceToken(_a), 'device-a');
    expect((await _stored()).keys, [SecureSyncCredentials.deviceTokenKey(_a)]);
  });

  test('retainOnly forgets the other groups and an unclaimed legacy pair, never the nickname',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSyncCredentials.legacyDeviceTokenKey: 'device-old',
      SecureSyncCredentials.legacyShareTokenKey: 'share-old',
    });
    final credentials = SecureSyncCredentials();
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');
    await credentials.saveShareToken(_b, 'share-b'); // a share token alone
    await credentials.saveNickname('Alice');

    expect(await credentials.retainOnly({_a}), {_b});

    expect(await _stored(), {
      SecureSyncCredentials.deviceTokenKey(_a): 'device-a',
      SecureSyncCredentials.shareTokenKey(_a): 'share-a',
      'sync.nickname': 'Alice',
    });
  });

  test('one nickname for every group, kept when a group is cleared', () async {
    final credentials = SecureSyncCredentials();
    expect(await credentials.nickname(), isNull);
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');
    await credentials.saveNickname('Alice');

    await credentials.clear(_a);

    expect(await credentials.nickname(), 'Alice');
  });

  test('MemorySyncCredentials behaves the same way', () async {
    final credentials = MemorySyncCredentials();
    await credentials.save(_a, deviceToken: 'device-a', shareToken: 'share-a');
    await credentials.saveShareToken(_b, 'share-b');
    await credentials.saveNickname('Alice');

    expect(await credentials.groupIds(), {_a});
    expect(await credentials.retainOnly({_a}), {_b});
    expect(await credentials.shareToken(_b), isNull);
    expect(await credentials.deviceToken(_a), 'device-a');
    await credentials.clear(_a);
    expect(await credentials.groupIds(), isEmpty);
    expect(await credentials.nickname(), 'Alice');
  });
}
