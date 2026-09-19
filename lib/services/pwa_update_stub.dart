import 'package:flutter/foundation.dart';

/// Native builds have no service worker: no update is ever waiting.
void listenForPwaUpdate(VoidCallback onReady) {}

void applyPwaUpdate() {}
