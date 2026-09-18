class Game {
  final int? id;
  final String name;
  final int? gameTypeId;
  final bool isLowestScoreWins;
  final DateTime createdAt;
  final DateTime? lastModified;

  /// When the game was declared over, or null while it is still open. Set from
  /// the board, the home-screen menu or the game-over dialog; cleared by
  /// reopening. Nothing is locked by it — a finished game still takes rounds
  /// and score edits. Synced as `ended_at`.
  final DateTime? finishedAt;

  /// The group this game is shared with, or null for a local game. Read-only here:
  /// sharing goes through `SyncStore.shareGame`, never through [toMap].
  final String? groupId;

  /// The row's stable identity, the same on every device that shares the game,
  /// or null for a [Game] built in memory and not yet stored. Read-only here,
  /// like [groupId]: `create` mints it. Device-local state about a game — the
  /// board's remembered "Continue playing" — is keyed by it rather than by the
  /// local [id], which a restore may renumber.
  final String? uuid;

  bool get isShared => groupId != null;

  bool get isFinished => finishedAt != null;

  Game({
    this.id,
    required this.name,
    this.gameTypeId,
    required this.isLowestScoreWins,
    DateTime? createdAt,
    this.lastModified,
    this.finishedAt,
    this.groupId,
    this.uuid,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gameTypeId': gameTypeId,
      'isLowestScoreWins': isLowestScoreWins ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
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
      finishedAt: map['finishedAt'] != null
          ? DateTime.parse(map['finishedAt'] as String)
          : null,
      groupId: map['group_id'] as String?,
      uuid: map['uuid'] as String?,
    );
  }

  /// [clearFinishedAt] reopens the game. It exists because `x ?? this.x` cannot
  /// express "set this back to null", and reopening is exactly that.
  Game copyWith({
    int? id,
    String? name,
    int? gameTypeId,
    bool? isLowestScoreWins,
    DateTime? createdAt,
    DateTime? lastModified,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      gameTypeId: gameTypeId ?? this.gameTypeId,
      isLowestScoreWins: isLowestScoreWins ?? this.isLowestScoreWins,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      groupId: groupId,
      uuid: uuid,
    );
  }
}
