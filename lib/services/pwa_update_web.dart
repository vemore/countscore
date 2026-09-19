import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// `window.countscorePwa`, set up by web/flutter_bootstrap.js before the app starts. It is
/// absent under a loader that does not define it.
@JS('countscorePwa')
external _CountscorePwa? get _pwa;

extension type _CountscorePwa._(JSObject _) implements JSObject {
  external bool get updateReady;
  external set onUpdateReady(JSFunction? callback);
  external void applyUpdate();
}

/// Calls [onReady] once a new build is installed and waiting — at once if it already is.
void listenForPwaUpdate(VoidCallback onReady) {
  final pwa = _pwa;
  if (pwa == null) return;
  pwa.onUpdateReady = onReady.toJS;
  if (pwa.updateReady) onReady();
}

/// Activates the waiting build; the loader then reloads every open page onto it.
void applyPwaUpdate() => _pwa?.applyUpdate();
