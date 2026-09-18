import 'package:flutter/material.dart';

enum PlayerDeadConditionType {
  over,
  under;

  String toDbString() => name;

  static PlayerDeadConditionType? fromDbString(String? value) {
    if (value == null) return null;
    return PlayerDeadConditionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlayerDeadConditionType.over,
    );
  }
}

enum GameOverConditionType {
  firstPlayerOver,
  firstPlayerUnder,
  lastPlayerOver,
  lastPlayerUnder;

  String toDbString() => name;

  static GameOverConditionType? fromDbString(String? value) {
    if (value == null) return null;
    return GameOverConditionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameOverConditionType.firstPlayerOver,
    );
  }
}

class GameType {
  final int? id;

  /// The stable identity of a built-in type, `null` for a type the user made or
  /// renamed. It carries the **displayed name** as well: see
  /// `lib/utils/game_type_name.dart`. [name] is only read for rows whose
  /// [builtinKey] is null, which is what makes the stored name of a built-in
  /// type inconsequential — two devices in different locales store different
  /// names for the same type and still converge. See .llmwiki/SchemaV10.md.
  final String? builtinKey;

  /// The seeded, untranslated name. For a built-in type this is a fallback only;
  /// render [builtinKey] through `gameTypeDisplayName` instead.
  final String name;
  final int iconCodePoint;
  final int cardColorValue;
  final bool isLowestScoreWins;
  final bool isDefault;
  final PlayerDeadConditionType? playerDeadConditionType;
  final int? playerDeadThreshold;
  final GameOverConditionType? gameOverConditionType;
  final int? gameOverThreshold;

  /// The rules the user wrote for this type, as Markdown. Null means "show the
  /// ruleset shipped for [rulesSlug] instead". User content: never translated,
  /// and it travels with the group like every other column here.
  final String? rules;

  /// Names the ruleset shipped in `assets/rules/`, or null for a type the user
  /// created. Kept apart from [name] because the name is editable — renaming a
  /// type must not lose its rules.
  final String? rulesSlug;

  GameType({
    this.id,
    this.builtinKey,
    required this.name,
    required this.iconCodePoint,
    required this.cardColorValue,
    required this.isLowestScoreWins,
    this.isDefault = false,
    this.playerDeadConditionType,
    this.playerDeadThreshold,
    this.gameOverConditionType,
    this.gameOverThreshold,
    this.rules,
    this.rulesSlug,
  });

  // The code point comes from the database, so it cannot be a constant. This is
  // the reason every build must pass --no-tree-shake-icons; see CLAUDE.md.
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get cardColor => Color(cardColorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'builtin_key': builtinKey,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'cardColorValue': cardColorValue,
      'isLowestScoreWins': isLowestScoreWins ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
      'playerDeadConditionType': playerDeadConditionType?.toDbString(),
      'playerDeadThreshold': playerDeadThreshold,
      'gameOverConditionType': gameOverConditionType?.toDbString(),
      'gameOverThreshold': gameOverThreshold,
      'rules': rules,
      'rules_slug': rulesSlug,
    };
  }

  factory GameType.fromMap(Map<String, dynamic> map) {
    return GameType(
      id: map['id'] as int?,
      builtinKey: map['builtin_key'] as String?,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      cardColorValue: map['cardColorValue'] as int,
      isLowestScoreWins: (map['isLowestScoreWins'] as int) == 1,
      isDefault: (map['isDefault'] as int?) == 1,
      playerDeadConditionType: PlayerDeadConditionType.fromDbString(
        map['playerDeadConditionType'] as String?,
      ),
      playerDeadThreshold: map['playerDeadThreshold'] as int?,
      gameOverConditionType: GameOverConditionType.fromDbString(
        map['gameOverConditionType'] as String?,
      ),
      gameOverThreshold: map['gameOverThreshold'] as int?,
      rules: map['rules'] as String?,
      rulesSlug: map['rules_slug'] as String?,
    );
  }

  /// Pass `clearBuiltinKey: true` to turn a built-in row into a user row — what
  /// renaming one does, so that the chosen name is what gets rendered.
  GameType copyWith({
    int? id,
    String? builtinKey,
    bool clearBuiltinKey = false,
    String? name,
    int? iconCodePoint,
    int? cardColorValue,
    bool? isLowestScoreWins,
    bool? isDefault,
    PlayerDeadConditionType? playerDeadConditionType,
    int? playerDeadThreshold,
    GameOverConditionType? gameOverConditionType,
    int? gameOverThreshold,
    String? rules,
    String? rulesSlug,
    bool clearRules = false,
  }) {
    return GameType(
      id: id ?? this.id,
      builtinKey: clearBuiltinKey ? null : (builtinKey ?? this.builtinKey),
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      isLowestScoreWins: isLowestScoreWins ?? this.isLowestScoreWins,
      isDefault: isDefault ?? this.isDefault,
      playerDeadConditionType: playerDeadConditionType ?? this.playerDeadConditionType,
      playerDeadThreshold: playerDeadThreshold ?? this.playerDeadThreshold,
      gameOverConditionType: gameOverConditionType ?? this.gameOverConditionType,
      gameOverThreshold: gameOverThreshold ?? this.gameOverThreshold,
      // `x ?? this.x` cannot express "put this back to null", and restoring the
      // shipped rules is exactly that — same shape as Game.clearFinishedAt.
      rules: clearRules ? null : (rules ?? this.rules),
      rulesSlug: rulesSlug ?? this.rulesSlug,
    );
  }

  // Types de jeux prédéfinis
  static GameType zapzap() => GameType(
        builtinKey: 'zapzap',
        name: 'ZapZap',
        rulesSlug: 'zapzap',
        iconCodePoint: Icons.flash_on.codePoint,
        cardColorValue: Colors.amber.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
      );

  // Uno and Président follow the box rule — highest total wins — since
  // feat/game-rules-seeds (2026-09-18). They were lowest-wins before, and no
  // migration flips an existing row: a type that already has games would see
  // its finished standings reversed. Only a new database seeds these values.
  // assets/rules/rules_<locale>.md describes the same scoring.

  /// The player who goes out collects the cards left in the other hands; the
  /// first total past 500 ends the game.
  static GameType uno() => GameType(
        builtinKey: 'uno',
        name: 'Uno',
        rulesSlug: 'uno',
        iconCodePoint: Icons.style.codePoint,
        cardColorValue: Colors.red.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 500,
      );

  static GameType scrabble() => GameType(
        builtinKey: 'scrabble',
        name: 'Scrabble',
        rulesSlug: 'scrabble',
        iconCodePoint: Icons.grid_on.codePoint,
        cardColorValue: Colors.green.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType autre() => GameType(
        builtinKey: 'other',
        name: 'Autre',
        iconCodePoint: Icons.sports_esports.codePoint,
        // Material deep purple, kept as a value: it is seeded data, not theme.
        cardColorValue: 0xFF673AB7,
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType skyjo() => GameType(
        builtinKey: 'skyjo',
        name: 'Skyjo',
        rulesSlug: 'skyjo',
        iconCodePoint: Icons.casino.codePoint,
        cardColorValue: Colors.blue.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 100,
      );

  /// The usual barème: 2 points for the Président, 1 for the Vice-Président,
  /// 0 for everyone else, played to 10 points.
  static GameType president() => GameType(
        builtinKey: 'president',
        name: 'Président',
        rulesSlug: 'president',
        iconCodePoint: Icons.workspace_premium.codePoint,
        cardColorValue: Colors.orange.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 10,
      );

  static GameType belote() => GameType(
        builtinKey: 'belote',
        name: 'Belote',
        rulesSlug: 'belote',
        iconCodePoint: Icons.diamond.codePoint,
        cardColorValue: const Color(0xFF8B4513).toARGB32(), // Brown color
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 1000,
      );

  static GameType tarot() => GameType(
        builtinKey: 'tarot',
        name: 'Tarot',
        rulesSlug: 'tarot',
        iconCodePoint: Icons.auto_awesome.codePoint,
        cardColorValue: Colors.indigo.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType bridge() => GameType(
        builtinKey: 'bridge',
        name: 'Bridge',
        rulesSlug: 'bridge',
        iconCodePoint: Icons.account_tree.codePoint,
        cardColorValue: Colors.teal.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType rami() => GameType(
        builtinKey: 'rami',
        name: 'Rami',
        rulesSlug: 'rami',
        iconCodePoint: Icons.style_outlined.codePoint,
        cardColorValue: const Color(0xFF9C27B0).toARGB32(), // Deep purple
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
      );


  // The long tail, added with schema v14.
  // Generic scoring shapes only: a winning direction and, where the game has a
  // widely known target total, one threshold. No published rulebook is
  // reproduced, and these are game *names* used descriptively.

  static GameType coinche() => GameType(
        builtinKey: 'coinche',
        name: 'Coinche',
        iconCodePoint: Icons.shield.codePoint,
        cardColorValue: Colors.brown.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 1000,
      );

  static GameType yahtzee() => GameType(
        builtinKey: 'yahtzee',
        name: 'Yahtzee',
        iconCodePoint: Icons.casino_outlined.codePoint,
        cardColorValue: Colors.cyan.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType phase10() => GameType(
        builtinKey: 'phase10',
        name: 'Phase 10',
        iconCodePoint: Icons.extension.codePoint,
        cardColorValue: Colors.pink.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
      );

  static GameType flip7() => GameType(
        builtinKey: 'flip7',
        name: 'Flip 7',
        iconCodePoint: Icons.offline_bolt.codePoint,
        cardColorValue: Colors.lightBlue.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 200,
      );

  static GameType milleBornes() => GameType(
        builtinKey: 'mille_bornes',
        name: 'Mille Bornes',
        iconCodePoint: Icons.rocket_launch.codePoint,
        cardColorValue: Colors.lightGreen.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 5000,
      );

  static GameType rummikub() => GameType(
        builtinKey: 'rummikub',
        name: 'Rummikub',
        iconCodePoint: Icons.deck.codePoint,
        cardColorValue: Colors.deepOrange.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType sixNimmt() => GameType(
        builtinKey: 'six_nimmt',
        name: '6 qui prend',
        iconCodePoint: Icons.local_fire_department.codePoint,
        cardColorValue: const Color(0xFFB71C1C).toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 66,
      );

  static GameType qwirkle() => GameType(
        builtinKey: 'qwirkle',
        name: 'Qwirkle',
        iconCodePoint: Icons.palette.codePoint,
        cardColorValue: Colors.purple.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType farkle() => GameType(
        builtinKey: 'farkle',
        name: 'Farkle',
        iconCodePoint: Icons.stars.codePoint,
        cardColorValue: const Color(0xFFFF8F00).toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 10000,
      );

  static GameType canasta() => GameType(
        builtinKey: 'canasta',
        name: 'Canasta',
        iconCodePoint: Icons.favorite.codePoint,
        cardColorValue: Colors.redAccent.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 5000,
      );

  static GameType wizard() => GameType(
        builtinKey: 'wizard',
        name: 'Wizard',
        iconCodePoint: Icons.emoji_objects.codePoint,
        cardColorValue: Colors.blueGrey.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType triomino() => GameType(
        builtinKey: 'triomino',
        name: 'Triomino',
        iconCodePoint: Icons.change_history.codePoint,
        cardColorValue: const Color(0xFF9E9D24).toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  /// The ten types seeded before schema v14, by the literal name they were
  /// seeded with. The v14 migration back-fills [builtinKey] on an existing
  /// install by matching these names, and skips them when it inserts the types
  /// the seed never had — so a type the user deleted stays deleted.
  static const seededNamesBeforeV14 = <String, String>{
    'zapzap': 'ZapZap',
    'uno': 'Uno',
    'scrabble': 'Scrabble',
    'other': 'Autre',
    'skyjo': 'Skyjo',
    'president': 'Président',
    'belote': 'Belote',
    'tarot': 'Tarot',
    'bridge': 'Bridge',
    'rami': 'Rami',
  };

  /// The built-in catalogue, in seed order. **Append only**: the first ten
  /// indices are what an install seeded before v14 already holds.
  static List<GameType> defaultGameTypes() {
    return [
      zapzap(),
      uno(),
      scrabble(),
      autre(),
      skyjo(),
      president(),
      belote(),
      tarot(),
      bridge(),
      rami(),
      coinche(),
      yahtzee(),
      phase10(),
      flip7(),
      milleBornes(),
      rummikub(),
      sixNimmt(),
      qwirkle(),
      farkle(),
      canasta(),
      wizard(),
      triomino(),
    ];
  }
}
