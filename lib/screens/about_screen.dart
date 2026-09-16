import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../utils/insets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Read once per process: the version cannot change while the app runs, and
  /// a future created in build() would restart the FutureBuilder on every
  /// rebuild.
  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  /// The app's own public listing. Opening it is the only honest way to offer
  /// a "rate this app" button: the Play in-app review sheet cannot be summoned
  /// on demand, and pretending otherwise would promise what the API refuses.
  static final Uri _playListing = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.vemore.countscore',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: withBottomInset(context, const EdgeInsets.all(24.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'store_listing/assets/icon_512.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final style = Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        );
                    final info = snapshot.data;
                    // An empty Text keeps the line's height while loading (or if
                    // the platform cannot answer), so nothing below it jumps.
                    return Text(
                      info == null ? '' : l10n.version(info.version),
                      style: style,
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.appDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 48),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.features,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFeature(
                          Icons.games,
                          l10n.featureDifferentGameTypes,
                        ),
                        _buildFeature(
                          Icons.people,
                          l10n.featurePlayerManagement,
                        ),
                        _buildFeature(
                          Icons.analytics,
                          l10n.featureDetailedStatistics,
                        ),
                        _buildFeature(Icons.palette, l10n.featureCustomization),
                        _buildFeature(
                          Icons.dark_mode,
                          l10n.featureDarkLightTheme,
                        ),
                        _buildFeature(Icons.group, l10n.featureGroupSharing),
                        _buildFeature(
                          Icons.auto_awesome,
                          l10n.featureGameAnalysis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(l10n.rateApp),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => launchUrl(
                      _playListing,
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.copyright),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.credits,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCredit(l10n.appIconCredit, l10n.artistName),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildCredit(String label, String author) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(author, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
