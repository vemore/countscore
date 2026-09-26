import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../utils/config_link.dart';

/// Settings → *Share by QR code*: a QR code carrying this device's server and,
/// when it is in a group, the group's invite code, as the link
/// `<PWA base>/#/join?s=…&g=…` ([encodeConfigLink]). Drawn on the device from
/// the `qr` package: nothing is sent anywhere to show it.
///
/// The PWA base is the address the user's own server serves the web app at
/// (`PWA_BASE_PATH` on its host), which the app cannot learn from the server.
/// The sheet asks for it once and keeps it (SharedPreferences
/// [ConfigShareSheet.prefsKey]); in the PWA it starts from the app's own address.
class ConfigShareSheet extends StatefulWidget {
  const ConfigShareSheet({super.key, this.runningPwaBase});

  /// Where the web app address is kept on this device.
  static const prefsKey = 'pwaBaseUrl';

  /// The PWA this code runs as, when it runs on the web: the starting value of
  /// the address field while none is stored. Null off the web.
  final String? runningPwaBase;

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ConfigShareSheet(
          runningPwaBase: kIsWeb ? pwaBaseFromUri(Uri.base) : null,
        ),
      );

  @override
  State<ConfigShareSheet> createState() => _ConfigShareSheetState();
}

class _ConfigShareSheetState extends State<ConfigShareSheet> {
  final _baseController = TextEditingController();

  /// The saved, valid base; null while none is.
  String? _base;
  String? _baseError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? stored;
    try {
      stored = (await SharedPreferences.getInstance()).getString(ConfigShareSheet.prefsKey);
    } catch (_) {
      // Storage unavailable: the field starts empty, or from the running PWA.
    }
    if (!mounted) return;
    final initial = normalizePwaBase(stored ?? '') ?? widget.runningPwaBase;
    setState(() {
      _base = initial;
      _baseController.text = initial ?? '';
    });
  }

  Future<void> _saveBase() async {
    final l10n = AppLocalizations.of(context)!;
    final check = BackendProvider.check(_baseController.text);
    if (check.url == null) {
      setState(() => _baseError = switch (check.error!) {
            BackendUrlError.empty => l10n.configShareWebAppNeeded,
            BackendUrlError.malformed => l10n.backendUrlInvalid,
            BackendUrlError.insecure => l10n.backendUrlInsecure,
          });
      return;
    }
    setState(() {
      _base = check.url;
      _baseError = null;
      _baseController.text = check.url!;
    });
    try {
      await (await SharedPreferences.getInstance())
          .setString(ConfigShareSheet.prefsKey, check.url!);
    } catch (_) {
      // Kept for this sheet only; asked again next time.
    }
  }

  @override
  void dispose() {
    _baseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final server = context.watch<BackendProvider>().baseUrl;
    final group = context.watch<GroupProvider>();
    final invite = group.isJoined ? group.shareToken : null;
    final base = _base;
    final link = server == null || base == null
        ? null
        : encodeConfigLink(base, ConfigLink(server: server, invite: invite));

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.configShareTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (server == null)
              Text(l10n.groupNeedsServer)
            else
              Text(invite == null
                  ? l10n.configShareExplainServer
                  : l10n.configShareExplainGroup(group.groupName ?? '')),
            const SizedBox(height: 16),
            if (link != null) ...[
              Center(
                child: ConfigQrCode(
                  key: const Key('config_share_qr'),
                  data: link,
                  semanticLabel: l10n.configShareQrLabel,
                ),
              ),
              Center(
                child: TextButton.icon(
                  key: const Key('config_share_copy'),
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.configShareCopyLink),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: link));
                    messenger.showSnackBar(SnackBar(content: Text(l10n.configShareLinkCopied)));
                  },
                ),
              ),
            ] else if (server != null)
              Text(l10n.configShareWebAppNeeded, key: const Key('config_share_needs_base')),
            const SizedBox(height: 16),
            TextField(
              key: const Key('config_share_base'),
              controller: _baseController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.configShareWebAppLabel,
                helperText: l10n.configShareWebAppHelper,
                helperMaxLines: 3,
                errorText: _baseError,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  key: const Key('config_share_base_save'),
                  icon: const Icon(Icons.check),
                  tooltip: l10n.save,
                  onPressed: _saveBase,
                ),
              ),
              onSubmitted: (_) => _saveBase(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A QR code of [data], black on white whatever the theme — a dark-on-light code
/// with its quiet zone is what every reader expects — at medium error correction.
class ConfigQrCode extends StatelessWidget {
  const ConfigQrCode({super.key, required this.data, this.size = 240, this.semanticLabel});

  /// The text the code carries.
  final String data;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(QrCode(payload: QrPayload.fromString(data)));
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _QrPainter(data, image)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.data, this.image);

  final String data;
  final QrImage image;

  /// The quiet zone the standard asks for around the code, in modules.
  static const _quiet = 4;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final count = image.moduleCount;
    final module = size.shortestSide / (count + 2 * _quiet);
    final dark = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    final path = Path();
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!image.isDark(row, col)) continue;
        path.addRect(Rect.fromLTWH(
          (col + _quiet) * module,
          (row + _quiet) * module,
          // A hair wider, so neighbouring modules leave no seam between them.
          module + 0.5,
          module + 0.5,
        ));
      }
    }
    canvas.drawPath(path, dark);
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data;
}
