import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // Section Thème
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Apparence',
              style: TextStyle(
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
                    title: const Text('Clair'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Sombre'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Système'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Écran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                title: const Text('Garder l\'écran allumé'),
                subtitle: const Text(
                  'Empêche l\'écran de se mettre en veille pendant une partie',
                ),
                value: settingsProvider.keepScreenAwake,
                onChanged: (value) {
                  settingsProvider.toggleKeepScreenAwake();
                },
              );
            },
          ),
          const Divider(),

          // Section Sauvegarde
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Sauvegarde',
              style: TextStyle(
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
                    title: const Text('Exporter la base de données'),
                    subtitle: const Text(
                      'Sauvegarder toutes vos parties dans un fichier',
                    ),
                    onTap: () async {
                      try {
                        final exportedPath = await settingsProvider.exportDatabase();
                        if (exportedPath != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Base de données exportée vers:\n$exportedPath'),
                              duration: const Duration(seconds: 4),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de l\'export: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('Importer une base de données'),
                    subtitle: const Text(
                      'Restaurer vos parties depuis un fichier de sauvegarde',
                    ),
                    onTap: () async {
                      // Afficher une boîte de dialogue de confirmation
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmation'),
                          content: const Text(
                            'L\'importation remplacera toutes vos données actuelles. '
                            'Une sauvegarde automatique sera créée avant l\'import.\n\n'
                            'Voulez-vous continuer ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Importer'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final success = await settingsProvider.importDatabase();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Base de données importée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Redémarrer l'application pour recharger les données
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Import réussi'),
                                  content: const Text(
                                    'La base de données a été importée. '
                                    'Veuillez redémarrer l\'application pour voir les changements.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
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
                                content: Text('Erreur lors de l\'import: $e'),
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
