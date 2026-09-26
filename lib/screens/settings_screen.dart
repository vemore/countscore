import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/group_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/insets.dart';
import '../widgets/config_share_sheet.dart';
import '../widgets/group_settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final BackendProvider _backend = context.read<BackendProvider>();
  late String? _shownUrl = _backend.baseUrl;
  late final TextEditingController _backendUrlController =
      TextEditingController(text: _shownUrl ?? '');
  bool _testingConnection = false;

  @override
  void initState() {
    super.initState();
    _backend.addListener(_backendChanged);
  }

  /// A server replaced from elsewhere — a shared configuration opened while
  /// Settings is on the stack — shows in the field; typing alone never moves it.
  void _backendChanged() {
    final url = _backend.baseUrl;
    if (url == _shownUrl) return;
    _shownUrl = url;
    _backendUrlController.text = url ?? '';
  }

  @override
  void dispose() {
    _backend.removeListener(_backendChanged);
    _backendUrlController.dispose();
    super.dispose();
  }

  /// Colours from the scheme, so a confirmation reads on the dark theme too and a
  /// failure looks like the analysis screen's.
  void _snack(String message, {bool ok = true}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: TextStyle(color: ok ? scheme.onPrimary : scheme.onError),
      ),
      backgroundColor: ok ? scheme.primary : scheme.error,
    ));
  }

  /// Clearing the server while in a group leaves the group, after asking.
  Future<bool> _clearServer() async {
    final l10n = AppLocalizations.of(context)!;
    final group = context.read<GroupProvider>();
    if (group.isJoined) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmation),
          content: Text(l10n.clearServerLeavesGroup),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.clear),
            ),
          ],
        ),
      );
      if (ok != true) return false;
      await group.leave();
    }
    if (!mounted) return false;
    await context.read<BackendProvider>().clear();
    return true;
  }

  /// Saves the typed URL, or clears the setting when the field is empty.
  Future<void> _saveBackendUrl() async {
    final l10n = AppLocalizations.of(context)!;
    final backend = context.read<BackendProvider>();
    final check = BackendProvider.check(_backendUrlController.text);

    if (check.url != null) {
      await backend.setBaseUrl(check.url!);
      if (!mounted) return;
      _backendUrlController.text = check.url!;
      _snack(l10n.serverUrlSaved);
      return;
    }

    switch (check.error!) {
      // An empty field is how the user turns the connected features back off,
      // not a mistake to complain about.
      case BackendUrlError.empty:
        if (!await _clearServer() || !mounted) return;
        _snack(l10n.serverUrlCleared);
      case BackendUrlError.malformed:
        _snack(l10n.backendUrlInvalid, ok: false);
      case BackendUrlError.insecure:
        _snack(l10n.backendUrlInsecure, ok: false);
    }
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    final backend = context.read<BackendProvider>();
    setState(() => _testingConnection = true);
    final ok = await backend.testConnection();
    if (!mounted) return;
    setState(() => _testingConnection = false);
    _snack(ok ? l10n.connectionOk : l10n.connectionFailed, ok: ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        // The last row clears the gesture bar, with room to spare.
        padding: withBottomInset(context, const EdgeInsets.only(bottom: 16)),
        children: [
          // Section Thème
          _SectionTitle(l10n.appearance),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return RadioGroup<ThemeMode>(
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.light),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.dark),
                      value: ThemeMode.dark,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(l10n.system),
                      value: ThemeMode.system,
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Section Serveur — pas de garde kIsWeb : la PWA en a besoin aussi.
          _SectionTitle(l10n.serverSection),
          Consumer<BackendProvider>(
            builder: (context, backend, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backendUrlDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _backendUrlController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.backendUrlLabel,
                        hintText: l10n.backendUrlHint,
                        border: const OutlineInputBorder(),
                        helperText: backend.isConfigured
                            ? null
                            : l10n.backendNotConfigured,
                      ),
                      onSubmitted: (_) => _saveBackendUrl(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          key: const Key('backend_url_save'),
                          onPressed: _testingConnection ? null : _saveBackendUrl,
                          child: Text(l10n.save),
                        ),
                        TextButton.icon(
                          key: const Key('backend_url_test'),
                          icon: _testingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: Text(l10n.testConnection),
                          onPressed: backend.isConfigured && !_testingConnection
                              ? _testConnection
                              : null,
                        ),
                        TextButton(
                          key: const Key('backend_url_clear'),
                          onPressed: backend.isConfigured && !_testingConnection
                              ? () async {
                                  if (!await _clearServer()) return;
                                  if (!context.mounted) return;
                                  _backendUrlController.clear();
                                  _snack(l10n.serverUrlCleared);
                                }
                              : null,
                          child: Text(l10n.clear),
                        ),
                        TextButton.icon(
                          key: const Key('config_share_open'),
                          icon: const Icon(Icons.qr_code_2),
                          label: Text(l10n.configShareOpen),
                          onPressed: backend.isConfigured && !_testingConnection
                              ? () => ConfigShareSheet.show(context)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Section Groupe — sous le serveur, dont elle dépend.
          _SectionTitle(l10n.groupSection),
          const GroupSettingsSection(),
          const Divider(),

          // Section Écran — on the web too: wakelock_plus holds a
          // navigator.wakeLock sentinel in the PWA.
          _SectionTitle(l10n.screen),
          SwitchListTile(
            key: const Key('keep_screen_awake'),
            title: Text(l10n.keepScreenAwake),
            subtitle: Text(l10n.keepScreenAwakeDescription),
            value: settings.keepScreenAwake,
            onChanged: (_) => settings.toggleKeepScreenAwake(),
          ),
          const Divider(),

          // Section Sons — bundled assets, on the web too; off by default.
          _SectionTitle(l10n.soundsSection),
          SwitchListTile(
            key: const Key('game_sounds'),
            title: Text(l10n.gameSounds),
            subtitle: Text(l10n.gameSoundsDescription),
            value: settings.gameSounds,
            onChanged: settings.setGameSounds,
          ),

          // Section Sauvegarde — heading and rows together, or neither: it
          // needs dart:io, so the PWA has none of it.
          if (settings.supportsDbExportImport) ...[
          const Divider(),
          _SectionTitle(l10n.backup),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_upload),
                    title: Text(l10n.exportDatabase),
                    subtitle: Text(l10n.exportDatabaseDescription),
                    onTap: () async {
                      try {
                        final exportedPath = await settingsProvider.exportDatabase();
                        if (exportedPath != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.databaseExportedTo}\n$exportedPath'),
                              duration: const Duration(seconds: 4),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.errorDuringExport} $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: Text(l10n.importDatabase),
                    subtitle: Text(l10n.importDatabaseDescription),
                    onTap: () async {
                      // Afficher une boîte de dialogue de confirmation
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.confirmation),
                          content: Text(l10n.importWarning),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(l10n.import),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final success = await settingsProvider.importDatabase();
                          if (success && context.mounted) {
                            // Afficher le message de succès
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.databaseImportedSuccessfully),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );

                            // Afficher un dialog et fermer l'application après un délai
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n.importSuccessful),
                                  content: Text(l10n.importSuccessMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        // Fermer l'application après une courte pause
                                        Future.delayed(const Duration(milliseconds: 500), () {
                                          SystemNavigator.pop();
                                        });
                                      },
                                      child: Text(l10n.ok),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${l10n.errorDuringImport} $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
          ], // end if (settings.supportsDbExportImport)
        ],
      ),
    );
  }
}

/// A section heading. Every one is followed by at least one row: a section whose
/// rows a platform lacks drops its heading with them.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          // From the scheme, not a hardcoded colour: the old violet was a
          // low-contrast blue-violet on the dark theme's black.
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
