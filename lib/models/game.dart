class Game {
  final int? id;
  final String name;
  final int? gameTypeId;
  final bool isLowestScoreWins;
  final DateTime createdAt;
  final DateTime? lastModified;

  Game({
    this.id,
    required this.name,
    this.gameTypeId,
    required this.isLowestScoreWins,
    DateTime? createdAt,
    this.lastModified,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gameTypeId': gameTypeId,
      'isLowestScoreWins': isLowestScoreWins ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      name: map['name'] as String,
      gameTypeId: map['gameTypeId'] as int?,
      isLowestScoreWins: (map['isLowestScoreWins'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'] as String)
          : null,
    );
  }

  Game copyWith({
    int? id,
    String? name,
    int? gameTypeId,
    bool? isLowestScoreWins,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      gameTypeId: gameTypeId ?? this.gameTypeId,
      isLowestScoreWins: isLowestScoreWins ?? this.isLowestScoreWins,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
