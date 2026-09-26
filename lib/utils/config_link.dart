import '../providers/backend_provider.dart';

/// The configuration a "share configuration" QR code carries: a server, and the
/// invite code of a group on it when the sharing device is in one.
///
/// The link has two shapes, both read by [parseConfigLink]:
/// - `https://<host><PWA_BASE_PATH>/#/join?s=<server>&g=<invite>` — what the QR
///   holds, readable by any phone's camera. Everything but the PWA's root sits
///   after `#`, which a browser never sends: the server and its logs see
///   `GET <PWA_BASE_PATH>/` and nothing else, and the invite code is a credential.
/// - `countscore://join?s=<server>&g=<invite>` — the hand-over from that page to
///   the Android app, device-local.
class ConfigLink {
  const ConfigLink({required this.server, this.invite});

  /// The backend URL, canonical as [BackendProvider.check] returns it.
  final String server;

  /// The group's invite code (`share_token`), or null for a server alone.
  final String? invite;

  @override
  bool operator ==(Object other) =>
      other is ConfigLink && other.server == server && other.invite == invite;

  @override
  int get hashCode => Object.hash(server, invite);

  /// Leaves the invite code out: it is a credential, and this ends up in logs.
  @override
  String toString() => 'ConfigLink($server, invite: ${invite != null})';
}

/// The app's own scheme, for the Android hand-over.
const configLinkScheme = 'countscore';

/// The hash route the PWA answers the link on.
const configLinkRoute = '/join';

const _serverParam = 's';
const _inviteParam = 'g';

/// An invite code as it may travel: printable ASCII, no space, bounded. The
/// server issues UUIDs; anything else is refused before it reaches it.
final _invitePattern = RegExp(r'^[\x21-\x7E]{1,128}$');

/// The PWA's root as a link base: an absolute `https://` URL (or `http://` on a
/// private network, like a server), without a trailing slash, a query or a
/// fragment. Null when [raw] is not one.
String? normalizePwaBase(String raw) => BackendProvider.check(raw).url;

/// The base of the PWA this code runs in, on the web: [base] is `Uri.base`, whose
/// path is the build's `--base-href` (the backend's `PWA_BASE_PATH`) and which may
/// carry the current hash route and an `index.html`. Null when it is not usable.
String? pwaBaseFromUri(Uri base) {
  if (!base.hasScheme || base.host.isEmpty) return null;
  var path = base.path;
  if (path.endsWith('/index.html')) {
    path = path.substring(0, path.length - 'index.html'.length);
  }
  final authority = base.hasPort ? '${base.host}:${base.port}' : base.host;
  return normalizePwaBase('${base.scheme}://$authority$path');
}

/// The link a QR code carries: `<pwaBase>/#/join?s=<server>&g=<invite>`, without
/// `g` for a server alone. Throws [ArgumentError] when [pwaBase] is not a base
/// [normalizePwaBase] accepts.
String encodeConfigLink(String pwaBase, ConfigLink config) {
  final base = normalizePwaBase(pwaBase);
  if (base == null) throw ArgumentError.value(pwaBase, 'pwaBase', 'not a PWA base URL');
  return '$base/#$configLinkRoute?${_query(config)}';
}

/// The Android hand-over: `countscore://join?s=<server>&g=<invite>`.
String encodeAppConfigLink(ConfigLink config) =>
    '$configLinkScheme://${configLinkRoute.substring(1)}?${_query(config)}';

String _query(ConfigLink config) => [
      '$_serverParam=${Uri.encodeQueryComponent(config.server)}',
      if (config.invite != null) '$_inviteParam=${Uri.encodeQueryComponent(config.invite!)}',
    ].join('&');

/// Reads a configuration link in either shape (see [ConfigLink]). Null when it is
/// neither, when its server is not one [BackendProvider.check] accepts, or when
/// its invite code is malformed. An empty `g` reads as no group.
///
/// On an `https://` link only what follows `#` counts: a `s` or `g` in a query
/// before it — which the server would have seen — is ignored.
ConfigLink? parseConfigLink(String raw) {
  final Map<String, String> params;
  try {
    final uri = Uri.parse(raw.trim());
    final scheme = uri.scheme.toLowerCase();
    if (scheme == configLinkScheme) {
      if (uri.host != configLinkRoute.substring(1) ||
          (uri.path.isNotEmpty && uri.path != '/') ||
          uri.hasFragment) {
        return null;
      }
      params = uri.queryParameters;
    } else if (scheme == 'https' || scheme == 'http') {
      if (!uri.hasFragment) return null;
      final route = Uri.parse(uri.fragment);
      if (route.hasScheme || route.hasAuthority || route.path != configLinkRoute) {
        return null;
      }
      params = route.queryParameters;
    } else {
      return null;
    }
  } on FormatException {
    return null;
  } on ArgumentError {
    // A malformed percent-escape in the query.
    return null;
  }

  final server = BackendProvider.check(params[_serverParam] ?? '').url;
  if (server == null) return null;
  final invite = params[_inviteParam]?.trim() ?? '';
  if (invite.isEmpty) return ConfigLink(server: server);
  if (!_invitePattern.hasMatch(invite)) return null;
  return ConfigLink(server: server, invite: invite);
}
