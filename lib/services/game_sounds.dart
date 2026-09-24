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
class AudioplayersSoundPlayer implements SoundPlayer {
  @override
  Future<void> play(GameSound sound) async {
    final player = AudioPlayer();
    player.onPlayerComplete.first.then((_) => player.dispose());
    await player.play(AssetSource(sound.asset), mode: PlayerMode.lowLatency);
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
