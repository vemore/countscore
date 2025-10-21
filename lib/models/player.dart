import 'package:flutter/material.dart';

class Player {
  final int? id;
  final int gameId;
  final String name;
  final int orderIndex;
  final int? colorValue;

  Player({
    this.id,
    required this.gameId,
    required this.name,
    required this.orderIndex,
    this.colorValue,
  });

  Color get color => colorValue != null ? Color(colorValue!) : Colors.blue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'name': name,
      'orderIndex': orderIndex,
      'colorValue': colorValue,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      gameId: map['gameId'] as int,
      name: map['name'] as String,
      orderIndex: map['orderIndex'] as int,
      colorValue: map['colorValue'] as int?,
    );
  }

  Player copyWith({
    int? id,
    int? gameId,
    String? name,
    int? orderIndex,
    int? colorValue,
  }) {
    return Player(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
