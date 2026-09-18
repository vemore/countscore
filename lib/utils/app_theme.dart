import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app's look — "Material soigné": a teal taken from the icon's podium,
/// Nunito, flat outlined cards. Both themes are built here and nowhere else.

/// Brand seed on the light theme: the icon's teal.
const Color kBrandSeedLight = Color(0xFF0E8F88);

/// Brand seed on the dark theme: the same teal, lifted to read on a dark surface.
const Color kBrandSeedDark = Color(0xFF5ED8CF);

/// The leader's gold — the crown, the leading total.
const Color kLeaderGold = Color(0xFFF2B705);

/// The bundled font family (`pubspec.yaml`, `assets/fonts/`). Scripts it does
/// not cover — Arabic, Devanagari, CJK — fall back to the system font.
const String kAppFontFamily = 'Nunito';

/// Adds the bundled font's SIL OFL 1.1 to the licence page (About → Licenses):
/// the licence must travel with the font, and Flutter lists only packages.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const [kAppFontFamily], text);
  });
}

/// The theme for [brightness].
ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seed = dark ? kBrandSeedDark : kBrandSeedLight;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    // Fidelity keeps the seed's own chroma: the tonal-spot default greys the
    // teal down to a colour the icon does not have.
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  ).copyWith(
    primary: seed,
    onPrimary: dark ? const Color(0xFF00201E) : Colors.white,
    surface: dark ? const Color(0xFF0E1716) : const Color(0xFFF3F8F7),
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: kAppFontFamily,
  );
  final text = base.textTheme;
  final cardColor = dark ? const Color(0xFF172221) : Colors.white;

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      // Sizes are explicit here: `ThemeData.textTheme` carries no geometry
      // until MaterialApp localizes it, so a style copied from it would be 14 px.
      titleTextStyle: TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    // White (or a raised dark surface) with a 1 px outline: no tint, no shadow.
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      extendedTextStyle: const TextStyle(
          fontFamily: kAppFontFamily, fontSize: 16, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(
            fontFamily: kAppFontFamily, fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
