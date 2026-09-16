import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The slice of `in_app_review` [ReviewPromptService] needs, so that the guard
/// logic can be unit-tested without a platform channel.
abstract class ReviewRequester {
  Future<bool> isAvailable();

  Future<void> requestReview();
}

/// The real one. `in_app_review` ships Android, iOS and macOS implementations
/// and **no web one**, so the PWA is excluded up front rather than left to
/// raise `MissingPluginException` from the plugin registry.
class PlatformReviewRequester implements ReviewRequester {
  const PlatformReviewRequester();

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await InAppReview.instance.isAvailable();
    } catch (_) {
      // An unsupported platform, or Play Services missing on the device.
      return false;
    }
  }

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// Decides whether to hand the Play in-app review sheet to the user after a
/// game ends.
///
/// The Play API is deliberately opaque: `requestReview()` may show nothing at
/// all (Google quotas the sheet per user and per app), and it never reports
/// whether a review was written. Play policy also forbids gating anything on
/// the rating, and forbids asking the user a question before the sheet — so
/// there is no pre-prompt here, and nothing branches on an outcome we cannot
/// observe. All this class can do is pick a good moment and then stay quiet.
class ReviewPromptService {
  ReviewPromptService({
    ReviewRequester? requester,
    Future<String> Function()? currentVersion,
    DateTime Function()? now,
  })  : _requester = requester ?? const PlatformReviewRequester(),
        _currentVersion = currentVersion ?? _platformVersion,
        _now = now ?? _systemNow;

  /// The instance the app uses. The "once per session" guard is instance
  /// state, so the screens must all go through this one.
  static final ReviewPromptService instance = ReviewPromptService();

  /// ISO-8601 instant of the first launch that ran [recordFirstLaunch].
  static const prefsFirstLaunch = 'reviewPromptFirstLaunch';

  /// How many games the user has declared over on this device.
  static const prefsGamesFinished = 'reviewPromptGamesFinished';

  /// The app version whose sheet was already requested.
  static const prefsPromptedVersion = 'reviewPromptVersion';

  /// Enough games to have an opinion worth writing down.
  static const minGamesFinished = 3;

  /// Long enough that the reviewer is a user rather than a visitor.
  static const minAge = Duration(days: 7);

  final ReviewRequester _requester;
  final Future<String> Function() _currentVersion;
  final DateTime Function() _now;

  /// Asking twice in one run would be noise even across two app versions.
  bool _requestedThisSession = false;

  @visibleForTesting
  bool get requestedThisSession => _requestedThisSession;

  static DateTime _systemNow() => DateTime.now();

  static Future<String> _platformVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  /// Starts the clock behind [minAge]. Call once from `main()`; it writes only
  /// when nothing is stored, so every later launch is a single read.
  ///
  /// An install that predates this feature starts its seven days at the
  /// upgrade, not at its real install date — the date is not recoverable, and
  /// waiting is the conservative half of that trade.
  Future<void> recordFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(prefsFirstLaunch) != null) return;
    await prefs.setString(prefsFirstLaunch, _now().toIso8601String());
  }

  /// The user has just declared a game over. Counts it, and asks for a review
  /// when every guard is satisfied.
  ///
  /// Returns whether the request was handed to the platform — which is *not*
  /// the same as the sheet having been shown, and never means a review exists.
  Future<bool> onGameFinished() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesFinished = (prefs.getInt(prefsGamesFinished) ?? 0) + 1;
    await prefs.setInt(prefsGamesFinished, gamesFinished);

    if (_requestedThisSession) return false;
    if (gamesFinished < minGamesFinished) return false;

    final firstLaunch =
        DateTime.tryParse(prefs.getString(prefsFirstLaunch) ?? '');
    // No stamp means the clock never started: stay quiet rather than treat an
    // unknown install date as an old one.
    if (firstLaunch == null) return false;
    if (_now().difference(firstLaunch) < minAge) return false;

    final version = await _currentVersion();
    if (prefs.getString(prefsPromptedVersion) == version) return false;

    // Availability is checked before the version is burned, so a device
    // without Play Services can still be asked after it gains them.
    if (!await _requester.isAvailable()) return false;

    _requestedThisSession = true;
    await prefs.setString(prefsPromptedVersion, version);
    try {
      await _requester.requestReview();
    } catch (_) {
      // Play swallowing the request is the documented normal case; a throw is
      // not worth surfacing to a user who did not ask for this dialog.
      return false;
    }
    return true;
  }
}
