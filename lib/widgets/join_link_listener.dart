import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/group_provider.dart';
import '../services/join_link_inbox.dart';
import '../utils/config_link.dart';
import '../utils/game_result_share.dart' show kPlayStoreUrl;
import 'replace_config_dialog.dart';

/// Opens the configuration links [inbox] receives — a scanned QR code, on the
/// Android app (`countscore://join?…`) or in the PWA (`#/join?…`) — as the
/// replace dialog ([showReplaceConfigDialog]). Wraps the home screen, the route
/// that stays at the bottom of the stack, so the dialog opens over whatever
/// screen is showing.
///
/// A link that does not parse opens nothing: the home screen stays as it is.
/// Links are taken one at a time, in order; each waits for
/// [GroupProvider.loaded], so on a cold start the dialog shows the group this
/// device is already in rather than none.
///
/// With [offerAppHandOver] (the PWA in an Android browser) a first question
/// offers the Android app — [openInApp] with the `intent://` link
/// ([encodeAndroidIntentLink]), which falls back on the Play listing — or to
/// continue in the browser with the same dialog as anywhere else. Never an
/// automatic redirect: a user who chose the PWA on Android stays in it, and a
/// browser leaves for an app only from a tap anyway.
class JoinLinkListener extends StatefulWidget {
  const JoinLinkListener({
    super.key,
    required this.inbox,
    required this.child,
    this.offerAppHandOver = false,
    this.openInApp,
  });

  final JoinLinkInbox inbox;
  final Widget child;
  final bool offerAppHandOver;

  /// Navigates to the hand-over link; required with [offerAppHandOver].
  final void Function(String intentLink)? openInApp;

  @override
  State<JoinLinkListener> createState() => _JoinLinkListenerState();
}

class _JoinLinkListenerState extends State<JoinLinkListener> {
  /// The link being handled, and those queued behind it.
  Future<void> _queue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    widget.inbox.attach(_receive);
  }

  @override
  void didUpdateWidget(JoinLinkListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.inbox, widget.inbox)) {
      oldWidget.inbox.detach(_receive);
      widget.inbox.attach(_receive);
    }
  }

  @override
  void dispose() {
    widget.inbox.detach(_receive);
    super.dispose();
  }

  void _receive(String link) {
    _queue = _queue.then((_) => _open(link)).catchError((Object e, StackTrace s) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: s, library: 'join link'),
      );
    });
  }

  Future<void> _open(String link) async {
    final config = parseReceivedConfigLink(link);
    if (config == null || !mounted) return;
    await context.read<GroupProvider>().loaded;
    if (!mounted) return;
    if (widget.offerAppHandOver) {
      final toApp = await showDialog<bool>(
        context: context,
        builder: (context) => const _HandOverDialog(),
      );
      if (toApp == null || !mounted) return;
      if (toApp) {
        widget.openInApp?.call(encodeAndroidIntentLink(config, fallbackUrl: kPlayStoreUrl));
        return;
      }
    }
    await showReplaceConfigDialog(context, config);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Android app or browser. Pops true for the app, false to stay, null when
/// dismissed (nothing then happens).
class _HandOverDialog extends StatelessWidget {
  const _HandOverDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      content: Text(l10n.joinLinkHandOverMessage, key: const Key('join_link_hand_over')),
      actions: [
        TextButton(
          key: const Key('join_link_continue_here'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.joinLinkContinueHere),
        ),
        FilledButton(
          key: const Key('join_link_open_in_app'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.joinLinkOpenInApp),
        ),
      ],
    );
  }
}
