import 'package:flutter/material.dart';

class GameType {
  final int? id;
  final String name;
  final int iconCodePoint;
  final int cardColorValue;
  final bool isLowestScoreWins;
  final bool isDefault;

  GameType({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.cardColorValue,
    required this.isLowestScoreWins,
    this.isDefault = false,
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
    );
  }

  GameType copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    int? cardColorValue,
    bool? isLowestScoreWins,
    bool? isDefault,
  }) {
    return GameType(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      isLowestScoreWins: isLowestScoreWins ?? this.isLowestScoreWins,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Types de jeux prédéfinis
  static GameType zapzap() => GameType(
        name: 'ZapZap',
        iconCodePoint: Icons.flash_on.codePoint,
        cardColorValue: Colors.amber.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
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

  static List<GameType> defaultGameTypes() {
    return [
      zapzap(),
      uno(),
      scrabble(),
      autre(),
    ];
  }
}
