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
  });

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
    );
  }

  // Types de jeux prédéfinis
  static GameType zapzap() => GameType(
        name: 'ZapZap',
        iconCodePoint: Icons.flash_on.codePoint,
        cardColorValue: Colors.amber.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
      );

  static GameType uno() => GameType(
        name: 'Uno',
        iconCodePoint: Icons.style.codePoint,
        cardColorValue: Colors.red.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
      );

  static GameType scrabble() => GameType(
        name: 'Scrabble',
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
        iconCodePoint: Icons.casino.codePoint,
        cardColorValue: Colors.blue.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 100,
      );

  static GameType president() => GameType(
        name: 'Président',
        iconCodePoint: Icons.workspace_premium.codePoint,
        cardColorValue: Colors.orange.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 11,
      );

  static GameType belote() => GameType(
        name: 'Belote',
        iconCodePoint: Icons.diamond.codePoint,
        cardColorValue: const Color(0xFF8B4513).toARGB32(), // Brown color
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 1000,
      );

  static GameType tarot() => GameType(
        name: 'Tarot',
        iconCodePoint: Icons.auto_awesome.codePoint,
        cardColorValue: Colors.indigo.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType bridge() => GameType(
        name: 'Bridge',
        iconCodePoint: Icons.account_tree.codePoint,
        cardColorValue: Colors.teal.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType rami() => GameType(
        name: 'Rami',
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
