import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The board's sounds, one bundled asset each (`assets/sounds/`, written by
/// `scripts/generate_sounds.py`, CC0).
enum GameSound {
  /// A player just went past the elimination threshold.
  elimination('sounds/elimination.wav'),

  /// The game type's rule just ended the game.
  victory('sounds/victory.wav'),

  /// The turn timer reached zero.
  timerEnd('sounds/timer_end.wav');

  const GameSound(this.asset);

  /// The path under `assets/`, as audioplayers' `AssetSource` wants it.
  final String asset;
}

/// What actually makes a sound. The one seam tests replace, with a player that
/// records what it was asked to play.
abstract class SoundPlayer {
  Future<void> play(GameSound sound);
}

/// audioplayers, one short-lived player per sound: they are a second long and
/// rare, so nothing is kept loaded. On the web the browser allows playback
/// only after a user gesture, and a score typed on the keypad is one.
///
/// Game sounds must not take the audio focus from the music the players have
/// on in another app: before the first player, [audioContext] is set as
/// audioplayers' global context — Android `USAGE_GAME` with a transient
/// may-duck focus request, iOS the `ambient` session category, which mixes
/// with other audio. A focus request is only given back when the player
/// stops, so each player plays in `mediaPlayer` mode, which reports its
/// completion (Android's low-latency SoundPool never does, and so never gave
/// the focus back), and is disposed on completion or after [releaseAfter],
/// whichever comes first.
class AudioplayersSoundPlayer implements SoundPlayer {
  /// The context every game sound plays in.
  static final AudioContext audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Longer than any bundled sound: a player still alive by then is disposed
  /// anyway, so its focus request never outlives it.
  static const Duration releaseAfter = Duration(seconds: 5);

  static Future<void>? _contextSet;

  /// Sets [audioContext] globally, once. The web has no audio context to set
  /// (audioplayers only logs that it is unsupported), so it is skipped there.
  static Future<void> _ensureContext() {
    if (kIsWeb) return Future.value();
    return _contextSet ??=
        AudioPlayer.global.setAudioContext(audioContext).catchError((Object e) {
      _contextSet = null;
      debugPrint('game sound context unavailable: $e');
    });
  }

  @override
  Future<void> play(GameSound sound) async {
    await _ensureContext();
    final player = AudioPlayer();
    var disposed = false;
    void release() {
      if (disposed) return;
      disposed = true;
      player.dispose().catchError((Object _) {});
    }

    player.onPlayerComplete.first.then((_) => release(), onError: (_) {});
    Timer(releaseAfter, release);
    try {
      await player.play(AssetSource(sound.asset), mode: PlayerMode.mediaPlayer);
    } catch (_) {
      release();
      rethrow;
    }
  }
}

/// The app's game sounds: elimination, victory and the turn timer's end.
///
/// One setting governs all three — "Game sounds" in Settings, stored in
/// SharedPreferences under [enabledKey] and **off by default**, so a board
/// that was never told otherwise is silent. Every failure to play is
/// swallowed: a sound is never worth an error on the board.
class GameSounds {
  /// On [SoundPlayer] when given (tests), on audioplayers otherwise.
  GameSounds([this._player]);

  /// The app-wide instance. Screens take a [GameSounds] parameter that
  /// defaults to it, so a test hands them one built on a fake player.
  static final GameSounds instance = GameSounds();

  /// SharedPreferences key of the "Game sounds" switch.
  static const String enabledKey = 'gameSounds';

  SoundPlayer? _player;

  /// Built on first use: a board whose sounds are off never creates a player.
  SoundPlayer get player => _player ??= AudioplayersSoundPlayer();

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
  }

  /// Plays [sound] if the setting is on; does nothing otherwise.
  Future<void> play(GameSound sound) async {
    try {
      if (!await isEnabled()) return;
      await player.play(sound);
    } catch (e) {
      debugPrint('game sound unavailable: $e');
    }
  }
}
