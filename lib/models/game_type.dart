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

  GameType copyWith({
    int? id,
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
        name: 'ZapZap',
        rulesSlug: 'zapzap',
        iconCodePoint: Icons.flash_on.codePoint,
        cardColorValue: Colors.amber.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
      );

  static GameType uno() => GameType(
        name: 'Uno',
        rulesSlug: 'uno',
        iconCodePoint: Icons.style.codePoint,
        cardColorValue: Colors.red.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
      );

  static GameType scrabble() => GameType(
        name: 'Scrabble',
        rulesSlug: 'scrabble',
        iconCodePoint: Icons.grid_on.codePoint,
        cardColorValue: Colors.green.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType autre() => GameType(
        name: 'Autre',
        iconCodePoint: Icons.sports_esports.codePoint,
        cardColorValue: Colors.deepPurple.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType skyjo() => GameType(
        name: 'Skyjo',
        rulesSlug: 'skyjo',
        iconCodePoint: Icons.casino.codePoint,
        cardColorValue: Colors.blue.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 100,
      );

  static GameType president() => GameType(
        name: 'Président',
        rulesSlug: 'president',
        iconCodePoint: Icons.workspace_premium.codePoint,
        cardColorValue: Colors.orange.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 11,
      );

  static GameType belote() => GameType(
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
        name: 'Tarot',
        rulesSlug: 'tarot',
        iconCodePoint: Icons.auto_awesome.codePoint,
        cardColorValue: Colors.indigo.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType bridge() => GameType(
        name: 'Bridge',
        rulesSlug: 'bridge',
        iconCodePoint: Icons.account_tree.codePoint,
        cardColorValue: Colors.teal.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType rami() => GameType(
        name: 'Rami',
        rulesSlug: 'rami',
        iconCodePoint: Icons.style_outlined.codePoint,
        cardColorValue: const Color(0xFF9C27B0).toARGB32(), // Deep purple
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
      );

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
    ];
  }
}
