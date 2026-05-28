class GameAnalysis {
  final int? id;
  final int gameId;
  final String content;
  final String? modelId;
  final DateTime generatedAt;

  GameAnalysis({
    this.id,
    required this.gameId,
    required this.content,
    this.modelId,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'content': content,
      'modelId': modelId,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory GameAnalysis.fromMap(Map<String, dynamic> map) {
    return GameAnalysis(
      id: map['id'] as int?,
      gameId: map['gameId'] as int,
      content: map['content'] as String,
      modelId: map['modelId'] as String?,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }

  GameAnalysis copyWith({
    int? id,
    int? gameId,
    String? content,
    String? modelId,
    DateTime? generatedAt,
  }) {
    return GameAnalysis(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      content: content ?? this.content,
      modelId: modelId ?? this.modelId,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
