class Score {
  final int? id;
  final int playerId;
  final int roundId;
  final int value;

  Score({
    this.id,
    required this.playerId,
    required this.roundId,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'roundId': roundId,
      'value': value,
    };
  }

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      id: map['id'] as int?,
      playerId: map['playerId'] as int,
      roundId: map['roundId'] as int,
      value: map['value'] as int,
    );
  }

  Score copyWith({
    int? id,
    int? playerId,
    int? roundId,
    int? value,
  }) {
    return Score(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      roundId: roundId ?? this.roundId,
      value: value ?? this.value,
    );
  }
}
