// GameSounds: one setting, off by default, and a sound that fails to play is
// never an error on the board.

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/services/game_sounds.dart';

import '../support/fake_sound_player.dart';

class _BrokenPlayer implements SoundPlayer {
  @override
  Future<void> play(GameSound sound) async => throw StateError('no audio');
}

void main() {
  test('off by default: nothing reaches the player', () async {
    SharedPreferences.setMockInitialValues({});
    final player = FakeSoundPlayer();
    await GameSounds(player).play(GameSound.victory);
    expect(player.played, isEmpty);
    expect(await GameSounds.isEnabled(), isFalse);
  });

  test('on: each sound reaches the player', () async {
    SharedPreferences.setMockInitialValues({});
    await GameSounds.setEnabled(true);
    final player = FakeSoundPlayer();
    final sounds = GameSounds(player);
    for (final s in GameSound.values) {
      await sounds.play(s);
    }
    expect(player.played, GameSound.values);
  });

  test('a player that fails is swallowed', () async {
    SharedPreferences.setMockInitialValues({GameSounds.enabledKey: true});
    await expectLater(GameSounds(_BrokenPlayer()).play(GameSound.elimination),
        completes);
  });

  test('every sound is a bundled asset path under assets/sounds/', () {
    for (final s in GameSound.values) {
      expect(s.asset, startsWith('sounds/'));
      expect(s.asset, endsWith('.wav'));
      expect(File('assets/${s.asset}').existsSync(), isTrue, reason: s.asset);
    }
  });

  test(
      'sounds duck the music of other apps instead of taking the audio focus '
      'from it', () {
    final ctx = AudioplayersSoundPlayer.audioContext;
    expect(ctx.android.usageType, AndroidUsageType.game);
    expect(ctx.android.audioFocus, AndroidAudioFocus.gainTransientMayDuck);
    // iOS: ambient mixes with other audio and respects the silent switch.
    expect(ctx.iOS.category, AVAudioSessionCategory.ambient);
  });
}
