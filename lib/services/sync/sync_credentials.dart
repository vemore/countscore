import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the two group secrets live: the device token (a bearer credential) and
/// the share token (what lets anyone join the group).
///
/// Neither goes in the database or in SharedPreferences, both of which are
/// plain files an export or a backup can carry off. On Android this is the
/// Keystore; on the web, `flutter_secure_storage` encrypts into localStorage,
/// which is the best a browser offers.
abstract class SyncCredentials {
  Future<String?> deviceToken();
  Future<String?> shareToken();
  Future<void> save({required String deviceToken, required String shareToken});
  Future<void> saveShareToken(String shareToken);
  Future<void> clear();
}

class SecureSyncCredentials implements SyncCredentials {
  SecureSyncCredentials([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _deviceTokenKey = 'sync.deviceToken';
  static const _shareTokenKey = 'sync.shareToken';

  @override
  Future<String?> deviceToken() => _storage.read(key: _deviceTokenKey);

  @override
  Future<String?> shareToken() => _storage.read(key: _shareTokenKey);

  @override
  Future<void> save({
    required String deviceToken,
    required String shareToken,
  }) async {
    await _storage.write(key: _deviceTokenKey, value: deviceToken);
    await _storage.write(key: _shareTokenKey, value: shareToken);
  }

  @override
  Future<void> saveShareToken(String shareToken) =>
      _storage.write(key: _shareTokenKey, value: shareToken);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _deviceTokenKey);
    await _storage.delete(key: _shareTokenKey);
  }
}

/// For tests, and for any platform where secure storage is unavailable.
class MemorySyncCredentials implements SyncCredentials {
  String? _device;
  String? _share;

  @override
  Future<String?> deviceToken() async => _device;

  @override
  Future<String?> shareToken() async => _share;

  @override
  Future<void> save({
    required String deviceToken,
    required String shareToken,
  }) async {
    _device = deviceToken;
    _share = shareToken;
  }

  @override
  Future<void> saveShareToken(String shareToken) async => _share = shareToken;

  @override
  Future<void> clear() async {
    _device = null;
    _share = null;
  }
}
