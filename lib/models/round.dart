class Round {
  final int? id;
  final int gameId;
  final int roundNumber;
  final String? comment;

  Round({
    this.id,
    required this.gameId,
    required this.roundNumber,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'roundNumber': roundNumber,
      'comment': comment,
    };
  }

  factory Round.fromMap(Map<String, dynamic> map) {
    return Round(
      id: map['id'] as int?,
      gameId: map['gameId'] as int,
      roundNumber: map['roundNumber'] as int,
      comment: map['comment'] as String?,
    );
  }

  Round copyWith({
    int? id,
    int? gameId,
    int? roundNumber,
    String? comment,
  }) {
    return Round(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      roundNumber: roundNumber ?? this.roundNumber,
      comment: comment ?? this.comment,
    );
  }
}
