import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/pwa_update.dart';

void _listenOnWeb(VoidCallback onReady) {
  if (kIsWeb) listenForPwaUpdate(onReady);
}

/// Offers a reload when a deploy has left a new build of the PWA waiting.
///
/// The service worker (web/service_worker.js) installs the new build beside the running
/// one; the page keeps the build it started with until the user takes the new one, so no
/// screen ever runs on files from two builds. The snackbar stays until acted on. Web only:
/// on Android the store updates the app.
class PwaUpdateListener extends StatefulWidget {
  const PwaUpdateListener({
    super.key,
    required this.messengerKey,
    required this.child,
    this.listen = _listenOnWeb,
    this.apply = applyPwaUpdate,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  /// Registers the callback run once an update is waiting (tests pass a fake).
  final void Function(VoidCallback onReady) listen;

  /// Activates the waiting build; the page then reloads onto it.
  final VoidCallback apply;

  @override
  State<PwaUpdateListener> createState() => _PwaUpdateListenerState();
}

class _PwaUpdateListenerState extends State<PwaUpdateListener> {
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    // After the first frame: the messenger and the localizations exist by then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.listen(_offer);
    });
  }

  void _offer() {
    final messenger = widget.messengerKey.currentState;
    final l10n = AppLocalizations.of(context);
    if (!mounted || _offered || messenger == null || l10n == null) return;
    _offered = true;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.pwaUpdateReady),
        persist: true,
        action: SnackBarAction(
          label: l10n.pwaUpdateReload,
          onPressed: widget.apply,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
