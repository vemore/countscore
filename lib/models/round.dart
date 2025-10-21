class Round {
  final int? id;
  final int gameId;
  final int roundNumber;

  Round({
    this.id,
    required this.gameId,
    required this.roundNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'roundNumber': roundNumber,
    };
  }

  factory Round.fromMap(Map<String, dynamic> map) {
    return Round(
      id: map['id'] as int?,
      gameId: map['gameId'] as int,
      roundNumber: map['roundNumber'] as int,
    );
  }

  Round copyWith({
    int? id,
    int? gameId,
    int? roundNumber,
  }) {
    return Round(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      roundNumber: roundNumber ?? this.roundNumber,
    );
  }
}
