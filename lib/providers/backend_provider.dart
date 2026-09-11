import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend_client.dart';

/// Why a URL the user typed was refused. Each value maps to one l10n string.
enum BackendUrlError {
  /// Nothing was typed. The UI reads this as "clear the setting", not as a
  /// mistake to complain about.
  empty,

  /// Not an absolute `http`/`https` URL with a host.
  malformed,

  /// `http://` on a public host. Cleartext is only allowed on a LAN.
  insecure,
}

/// The outcome of checking one raw string: exactly one of the two is non-null.
typedef BackendUrlCheck = ({String? url, BackendUrlError? error});

/// Holds the backend base URL the user configured, if any.
///
/// There is deliberately **no default**. A fresh install has no server, so the
/// connected features are switched off and the app makes no network request at
/// all — see `README.md` (Privacy). Users who want them install the FastAPI
/// service from `backend/` on their own server and point the app at it.
class BackendProvider with ChangeNotifier {
  static const _prefsKey = 'backendUrl';

  /// Optional build-time seed, used only when nothing is stored yet:
  /// `--dart-define=BACKEND_URL=…`. Empty when the flag is absent, which is
  /// the case for every published build.
  static const seed = String.fromEnvironment('BACKEND_URL');

  String? _baseUrl;

  BackendProvider(this._baseUrl);

  /// Read once before `runApp`, like [ThemeProvider.load], so the ZapZap menu
  /// entry does not appear and then vanish on the second frame.
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) return stored.isEmpty ? null : stored;
    return check(seed).url;
  }

  /// The configured origin, without a trailing slash, or null.
  String? get baseUrl => _baseUrl;

  /// Whether the connected features are available at all.
  bool get isConfigured => _baseUrl != null;

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
  }

  /// Turns the connected features back off. The empty string is stored rather
  /// than removing the key, so a cleared setting is never re-seeded from
  /// `--dart-define` on the next launch.
  Future<void> clear() async {
    _baseUrl = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, '');
  }

  /// Asks the configured server for `GET /health`. False when nothing is
  /// configured, or when the server does not answer 200.
  Future<bool> testConnection() async {
    final url = _baseUrl;
    if (url == null) return false;
    return BackendClient(url).health();
  }

  /// Validates and canonicalises a URL the user typed.
  ///
  /// Accepts `https://` anywhere, and `http://` only on a private or loopback
  /// address — a self-hosted backend on a home LAN is the case that needs it.
  /// Android permits cleartext at the platform level (see
  /// `android/app/src/main/res/xml/network_security_config.xml`), because its
  /// network security config matches hostnames and cannot express an address
  /// range; this function is what actually enforces the rule.
  static BackendUrlCheck check(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (url: null, error: BackendUrlError.empty);

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.isAbsolute ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return (url: null, error: BackendUrlError.malformed);
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return (url: null, error: BackendUrlError.malformed);
    }
    if (scheme == 'http' && !isPrivateHost(uri.host)) {
      return (url: null, error: BackendUrlError.insecure);
    }

    // Keep any base path (a backend behind /countscore/), minus its trailing
    // slash, so callers can always append "/health".
    var path = uri.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final authority = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    return (url: '$scheme://$authority$path', error: null);
  }

  /// Convenience for tests and for [load]: the canonical URL, or null.
  static String? normalize(String raw) => check(raw).url;

  /// Whether cleartext to this host stays on a private network.
  ///
  /// RFC 1918 and loopback IPv4, IPv6 loopback and unique-local, plus the
  /// hostnames a home network hands out.
  static bool isPrivateHost(String host) {
    final name = host.toLowerCase();
    if (name == 'localhost') return true;
    for (final suffix in const ['.local', '.lan', '.home', '.internal']) {
      if (name.endsWith(suffix)) return true;
    }

    final v4 = name.split('.');
    if (v4.length == 4) {
      final octets = v4.map(int.tryParse).toList();
      if (octets.every((o) => o != null && o >= 0 && o <= 255)) {
        final a = octets[0]!;
        final b = octets[1]!;
        if (a == 10 || a == 127) return true;
        if (a == 192 && b == 168) return true;
        if (a == 172 && b >= 16 && b <= 31) return true;
        if (a == 169 && b == 254) return true;
        return false;
      }
    }

    if (name == '::1') return true;
    // fc00::/7 — unique local addresses.
    if (name.startsWith('fc') || name.startsWith('fd')) return name.contains(':');

    return false;
  }
}
