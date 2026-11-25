import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the group secrets live, one pair per group this device is in: the
/// device token (a bearer credential) and the share token (what lets anyone
/// join the group). Beside them, the nickname this device goes by in every
/// group — one for all of them, and no secret, but it belongs to the device
/// as they do, so it is kept with them.
///
/// None goes in the database or in SharedPreferences, both of which are plain
/// files an export or a backup can carry off. On Android this is the Keystore;
/// on the web, `flutter_secure_storage` encrypts into localStorage, which is
/// the best a browser offers.
///
/// Keyed by group id since schema v23 (`.llmwiki/Sync.md`). The single pair an
/// older version stored is moved to the first group it is read for, then
/// deleted: an upgraded install reads it for its one membership on start.
abstract class SyncCredentials {
  Future<String?> deviceToken(String groupId);
  Future<String?> shareToken(String groupId);
  Future<void> save(
    String groupId, {
    required String deviceToken,
    required String shareToken,
  });
  Future<void> saveShareToken(String groupId, String shareToken);

  /// Forgets [groupId]'s pair. The nickname stays: it is the device's.
  Future<void> clear(String groupId);

  /// The groups a device token is stored for.
  Future<Set<String>> groupIds();

  /// Forgets the pair of every group not in [groupIds], and a legacy pair not
  /// claimed yet. Returns the groups forgotten.
  Future<Set<String>> retainOnly(Set<String> groupIds);

  /// The nickname this device goes by in its groups, or null before any.
  Future<String?> nickname();
  Future<void> saveNickname(String nickname);
}

class SecureSyncCredentials implements SyncCredentials {
  SecureSyncCredentials([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// The single pair stored before schema v23.
  static const legacyDeviceTokenKey = 'sync.deviceToken';
  static const legacyShareTokenKey = 'sync.shareToken';

  static const _groupPrefix = 'sync.group.';
  static const _deviceSuffix = '.deviceToken';
  static const _shareSuffix = '.shareToken';
  static const _nicknameKey = 'sync.nickname';

  static String deviceTokenKey(String groupId) => '$_groupPrefix$groupId$_deviceSuffix';
  static String shareTokenKey(String groupId) => '$_groupPrefix$groupId$_shareSuffix';

  @override
  Future<String?> deviceToken(String groupId) => _read(deviceTokenKey(groupId), groupId);

  @override
  Future<String?> shareToken(String groupId) => _read(shareTokenKey(groupId), groupId);

  Future<String?> _read(String key, String groupId) async {
    final value = await _storage.read(key: key);
    if (value != null) return value;
    if (!await _adoptLegacy(groupId)) return null;
    return _storage.read(key: key);
  }

  /// Moves the pre-v23 pair under [groupId], unless that group already has a
  /// pair, then deletes it. Written before it is deleted, so an interruption
  /// leaves the token in one place at least. True when a pair was found.
  Future<bool> _adoptLegacy(String groupId) async {
    final device = await _storage.read(key: legacyDeviceTokenKey);
    final share = await _storage.read(key: legacyShareTokenKey);
    if (device == null && share == null) return false;
    if (device != null && await _storage.read(key: deviceTokenKey(groupId)) == null) {
      await _storage.write(key: deviceTokenKey(groupId), value: device);
      if (share != null) await _storage.write(key: shareTokenKey(groupId), value: share);
    }
    await _deleteLegacy();
    return true;
  }

  Future<void> _deleteLegacy() async {
    await _storage.delete(key: legacyDeviceTokenKey);
    await _storage.delete(key: legacyShareTokenKey);
  }

  @override
  Future<void> save(
    String groupId, {
    required String deviceToken,
    required String shareToken,
  }) async {
    await _storage.write(key: deviceTokenKey(groupId), value: deviceToken);
    await _storage.write(key: shareTokenKey(groupId), value: shareToken);
  }

  @override
  Future<void> saveShareToken(String groupId, String shareToken) =>
      _storage.write(key: shareTokenKey(groupId), value: shareToken);

  @override
  Future<void> clear(String groupId) async {
    await _storage.delete(key: deviceTokenKey(groupId));
    await _storage.delete(key: shareTokenKey(groupId));
  }

  @override
  Future<Set<String>> groupIds() => _groupsWith(const [_deviceSuffix]);

  /// The groups a key with one of [suffixes] is stored for.
  Future<Set<String>> _groupsWith(List<String> suffixes) async {
    final keys = (await _storage.readAll()).keys;
    return {
      for (final key in keys)
        for (final suffix in suffixes)
          if (key.startsWith(_groupPrefix) &&
              key.endsWith(suffix) &&
              key.length > _groupPrefix.length + suffix.length)
            key.substring(_groupPrefix.length, key.length - suffix.length),
    };
  }

  @override
  Future<Set<String>> retainOnly(Set<String> groupIds) async {
    final forgotten =
        (await _groupsWith(const [_deviceSuffix, _shareSuffix])).difference(groupIds);
    for (final groupId in forgotten) {
      await clear(groupId);
    }
    await _deleteLegacy();
    return forgotten;
  }

  @override
  Future<String?> nickname() => _storage.read(key: _nicknameKey);

  @override
  Future<void> saveNickname(String nickname) =>
      _storage.write(key: _nicknameKey, value: nickname);
}

/// For tests, and for any platform where secure storage is unavailable.
class MemorySyncCredentials implements SyncCredentials {
  final _device = <String, String>{};
  final _share = <String, String>{};
  String? _nickname;

  @override
  Future<String?> deviceToken(String groupId) async => _device[groupId];

  @override
  Future<String?> shareToken(String groupId) async => _share[groupId];

  @override
  Future<void> save(
    String groupId, {
    required String deviceToken,
    required String shareToken,
  }) async {
    _device[groupId] = deviceToken;
    _share[groupId] = shareToken;
  }

  @override
  Future<void> saveShareToken(String groupId, String shareToken) async =>
      _share[groupId] = shareToken;

  @override
  Future<void> clear(String groupId) async {
    _device.remove(groupId);
    _share.remove(groupId);
  }

  @override
  Future<Set<String>> groupIds() async => _device.keys.toSet();

  @override
  Future<Set<String>> retainOnly(Set<String> groupIds) async {
    final forgotten = {..._device.keys, ..._share.keys}.difference(groupIds);
    for (final groupId in forgotten) {
      await clear(groupId);
    }
    return forgotten;
  }

  @override
  Future<String?> nickname() async => _nickname;

  @override
  Future<void> saveNickname(String nickname) async => _nickname = nickname;
}
