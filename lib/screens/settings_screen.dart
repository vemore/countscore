import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/backend_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _backendUrlController =
      TextEditingController(text: context.read<BackendProvider>().baseUrl ?? '');
  bool _testingConnection = false;

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
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
        await backend.clear();
        if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // Section Thème
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.appearance,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.serverSection,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
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
                                  await backend.clear();
                                  if (!context.mounted) return;
                                  _backendUrlController.clear();
                                  _snack(l10n.serverUrlCleared);
                                }
                              : null,
                          child: Text(l10n.clear),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Section Écran
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.screen,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          if (!kIsWeb)
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return SwitchListTile(
                  title: Text(l10n.keepScreenAwake),
                  subtitle: Text(l10n.keepScreenAwakeDescription),
                  value: settingsProvider.keepScreenAwake,
                  onChanged: (value) {
                    settingsProvider.toggleKeepScreenAwake();
                  },
                );
              },
            ),
          if (!kIsWeb) const Divider(),

          // Section Sauvegarde (mobile/desktop only)
          if (!kIsWeb) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.backup,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
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
          ], // end if (!kIsWeb)
        ],
      ),
    );
  }
}
