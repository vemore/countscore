import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.light),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.dark),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.system),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value!);
                    },
                  ),
                ],
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
          const Divider(),

          // Section Sauvegarde
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
        ],
      ),
    );
  }
}
