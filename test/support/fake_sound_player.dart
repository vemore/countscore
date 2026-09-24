import 'package:countscore/services/game_sounds.dart';

/// A [SoundPlayer] that plays nothing and remembers what it was asked to play,
/// in order. Wrapped in a real [GameSounds], so the "Game sounds" setting in
/// SharedPreferences still decides whether it is asked at all.
class FakeSoundPlayer implements SoundPlayer {
  final List<GameSound> played = [];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);
}
