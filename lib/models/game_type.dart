import 'package:flutter/material.dart';

import 'keypad_shortcut.dart';

export 'keypad_shortcut.dart';

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

  /// The stable identity of a built-in type, `null` for a type the user made or
  /// renamed. It carries the **displayed name** as well: see
  /// `lib/utils/game_type_name.dart`. [name] is only read for rows whose
  /// [builtinKey] is null, which is what makes the stored name of a built-in
  /// type inconsequential — two devices in different locales store different
  /// names for the same type and still converge. See .llmwiki/SchemaV10.md.
  final String? builtinKey;

  /// The seeded, untranslated name. For a built-in type this is a fallback only;
  /// render [builtinKey] through `gameTypeDisplayName` instead.
  final String name;
  final int iconCodePoint;
  final int cardColorValue;
  final bool isLowestScoreWins;

  /// **Historical only: nothing reads it, and nothing new may.** It means "this
  /// row was written by *this device's* seed" and nothing more — a built-in
  /// type that arrived from a group is inserted with 0
  /// (`lib/services/sync/sync_store.dart`, `_applyGameType`), so it does not
  /// separate "built in" from "the user's own" as soon as a group exists.
  /// [builtinKey] is what does that, and it is the only test any migration,
  /// query or screen may use. The two back-fills that still select on it
  /// (`applyV13`, `applyV14`) are past steps, and the pre-1.3.1 editor cleared
  /// it on every save, which is precisely why they could not repair the rows
  /// `applyV18` repairs. See .llmwiki/SchemaV10.md.
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

  /// The score keypad's extra key for this type — a value, or an operation on
  /// the score typed — or null for a plain 0. Stored and pushed as
  /// `keypad_shortcut` (schema v21); a malformed stored value reads as null.
  final KeypadShortcut? keypadShortcut;

  GameType({
    this.id,
    this.builtinKey,
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
    this.keypadShortcut,
  });

  // The code point comes from the database, so it cannot be a constant. This is
  // the reason every build must pass --no-tree-shake-icons; see CLAUDE.md.
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get cardColor => Color(cardColorValue);

  /// Whether [total] puts a player out under this type's elimination rule.
  /// False for a type without one.
  ///
  /// `over` is strict — out once a total **exceeds** the threshold — as the
  /// ZapZap and Rami rules say. 6 qui prend, whose box rule stops at 66, is
  /// seeded with 65 for that reason (new databases since 2026-09-19). The
  /// board, the ranking and the end screen all read this one rule.
  bool isEliminated(int total) {
    final threshold = playerDeadThreshold;
    final condition = playerDeadConditionType;
    if (threshold == null || condition == null) return false;
    return switch (condition) {
      PlayerDeadConditionType.over => total > threshold,
      PlayerDeadConditionType.under => total < threshold,
    };
  }

  /// Whether [total] is within 20 points of the elimination threshold, and
  /// not past it — the orange total on the board and the rankings.
  bool isNearElimination(int total) {
    final threshold = playerDeadThreshold;
    final condition = playerDeadConditionType;
    if (threshold == null || condition == null) return false;
    if (isEliminated(total)) return false;
    return switch (condition) {
      PlayerDeadConditionType.over => total >= threshold - 20,
      PlayerDeadConditionType.under => total <= threshold + 20,
    };
  }

  /// Whether the game-over rule of this type is met by these player totals.
  /// False when the type has no rule.
  ///
  /// `firstPlayerOver` means **reaches**: a total equal to the threshold ends
  /// the game, as the box rules the thresholds come from say — Président is won
  /// at 10, Uno at 500, Skyjo stops at 100 or more. It was strictly greater
  /// until 2026-09-19, which asked for one more hand. `firstPlayerUnder` keeps
  /// its strict comparison. `gameRulesEndFirstOver` and the texts in
  /// `assets/rules/` say the same.
  ///
  /// `lastPlayerOver` and `lastPlayerUnder` are **last player standing**: the
  /// game ends once every player *but one* is past the threshold, which is what
  /// `gameRulesEndLastOver` has always promised. They tested *every* player,
  /// the survivor included, until 2026-09-20 — a condition that never fired,
  /// because a player who is out stops being dealt in and the survivor's total
  /// never moves again (`wip/done/2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset.md`).
  bool isGameOver(Iterable<int> totals) {
    final type = gameOverConditionType;
    final threshold = gameOverThreshold;
    if (type == null || threshold == null) return false;
    switch (type) {
      case GameOverConditionType.firstPlayerOver:
        return totals.any((total) => total >= threshold);
      case GameOverConditionType.firstPlayerUnder:
        return totals.any((total) => total < threshold);
      case GameOverConditionType.lastPlayerOver:
        return _lastPlayerStanding(totals, (total) => total > threshold);
      case GameOverConditionType.lastPlayerUnder:
        return _lastPlayerStanding(totals, (total) => total < threshold);
    }
  }

  /// True when [isOut] holds for every total but one — or for all of them, a
  /// game everybody left at the same time.
  ///
  /// A table of fewer than two players has nobody to be the *last* one
  /// standing, so it never ends this way: a solo game would otherwise be over
  /// on its first round.
  static bool _lastPlayerStanding(
    Iterable<int> totals,
    bool Function(int total) isOut,
  ) {
    final all = totals.toList(growable: false);
    if (all.length < 2) return false;
    return all.where((total) => !isOut(total)).length <= 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'builtin_key': builtinKey,
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
      'keypad_shortcut': keypadShortcut?.encode(),
    };
  }

  factory GameType.fromMap(Map<String, dynamic> map) {
    return GameType(
      id: map['id'] as int?,
      builtinKey: map['builtin_key'] as String?,
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
      keypadShortcut: KeypadShortcut.decode(map['keypad_shortcut']),
    );
  }

  /// Pass `clearBuiltinKey: true` to turn a built-in row into a user row — what
  /// renaming one does, so that the chosen name is what gets rendered.
  ///
  /// `clearPlayerDeadCondition` and `clearGameOverCondition` drop a condition
  /// *and* its threshold, which `x ?? this.x` cannot express — the editor needs
  /// them to save *None* over a condition the type used to have.
  GameType copyWith({
    int? id,
    String? builtinKey,
    bool clearBuiltinKey = false,
    String? name,
    int? iconCodePoint,
    int? cardColorValue,
    bool? isLowestScoreWins,
    bool? isDefault,
    PlayerDeadConditionType? playerDeadConditionType,
    int? playerDeadThreshold,
    bool clearPlayerDeadCondition = false,
    GameOverConditionType? gameOverConditionType,
    int? gameOverThreshold,
    bool clearGameOverCondition = false,
    String? rules,
    String? rulesSlug,
    bool clearRules = false,
    KeypadShortcut? keypadShortcut,
    bool clearKeypadShortcut = false,
  }) {
    return GameType(
      id: id ?? this.id,
      builtinKey: clearBuiltinKey ? null : (builtinKey ?? this.builtinKey),
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      isLowestScoreWins: isLowestScoreWins ?? this.isLowestScoreWins,
      isDefault: isDefault ?? this.isDefault,
      playerDeadConditionType: clearPlayerDeadCondition
          ? null
          : (playerDeadConditionType ?? this.playerDeadConditionType),
      playerDeadThreshold: clearPlayerDeadCondition
          ? null
          : (playerDeadThreshold ?? this.playerDeadThreshold),
      gameOverConditionType: clearGameOverCondition
          ? null
          : (gameOverConditionType ?? this.gameOverConditionType),
      gameOverThreshold: clearGameOverCondition
          ? null
          : (gameOverThreshold ?? this.gameOverThreshold),
      // `x ?? this.x` cannot express "put this back to null", and restoring the
      // shipped rules is exactly that — same shape as Game.clearFinishedAt.
      rules: clearRules ? null : (rules ?? this.rules),
      rulesSlug: rulesSlug ?? this.rulesSlug,
      keypadShortcut: clearKeypadShortcut
          ? null
          : (keypadShortcut ?? this.keypadShortcut),
    );
  }

  // Types de jeux prédéfinis

  // The keypad shortcuts (schema v21) follow wip/done/2026-09-18-keypad-has-no-
  // per-game-shortcut.md, checked against assets/rules/rules_fr.md: ZapZap
  // "0 ZapZap", Skyjo ×2 (the closer doubled when not strictly lowest,
  // positive scores only), Belote 162 (the defence when the taker is dedans),
  // Scrabble +50 (seven letters), Rami 100 (nothing laid down). None for Uno,
  // Président, Tarot and Bridge; the others wait for their rules. `applyV21`
  // back-fills existing rows from these seeds (`keypadShortcutSeeds`).

  // The three types that play to a last survivor — ZapZap, Rami and 6 qui
  // prend, the only ones with a `playerDeadConditionType` — end on
  // `lastPlayerOver` at the same threshold that puts a player out
  // (feat/last-player-standing, 2026-09-20). They carried no game-over
  // condition at all before, which is why a game with one player left still
  // offered another round. Unlike Uno and Président below, an existing row
  // with no end gets this one from schema v20 (`applyV20`,
  // lib/services/schema_steps.dart); a condition the user set is kept.
  static GameType zapzap() => GameType(
        builtinKey: 'zapzap',
        name: 'ZapZap',
        rulesSlug: 'zapzap',
        iconCodePoint: Icons.flash_on.codePoint,
        cardColorValue: Colors.amber.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        keypadShortcut: KeypadShortcut.value(0, label: '0 ZapZap'),
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
        gameOverConditionType: GameOverConditionType.lastPlayerOver,
        gameOverThreshold: 100,
      );

  // Uno and Président follow the box rule — highest total wins — since
  // feat/game-rules-seeds (2026-09-18). They were lowest-wins before, and no
  // migration flips an existing row: a type that already has games would see
  // its finished standings reversed. Only a new database seeds these values.
  // assets/rules/rules_<locale>.md describes the same scoring.

  /// The player who goes out collects the cards left in the other hands; the
  /// first total past 500 ends the game.
  static GameType uno() => GameType(
        builtinKey: 'uno',
        name: 'Uno',
        rulesSlug: 'uno',
        iconCodePoint: Icons.style.codePoint,
        cardColorValue: Colors.red.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 500,
      );

  static GameType scrabble() => GameType(
        builtinKey: 'scrabble',
        name: 'Scrabble',
        rulesSlug: 'scrabble',
        iconCodePoint: Icons.grid_on.codePoint,
        cardColorValue: Colors.green.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        keypadShortcut: KeypadShortcut.add(50),
      );

  static GameType autre() => GameType(
        builtinKey: 'other',
        name: 'Autre',
        iconCodePoint: Icons.sports_esports.codePoint,
        // Material deep purple, kept as a value: it is seeded data, not theme.
        cardColorValue: 0xFF673AB7,
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType skyjo() => GameType(
        builtinKey: 'skyjo',
        name: 'Skyjo',
        rulesSlug: 'skyjo',
        iconCodePoint: Icons.casino.codePoint,
        cardColorValue: Colors.blue.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        keypadShortcut: KeypadShortcut.multiply(2),
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 100,
      );

  /// The usual barème: 2 points for the Président, 1 for the Vice-Président,
  /// 0 for everyone else, played to 10 points.
  static GameType president() => GameType(
        builtinKey: 'president',
        name: 'Président',
        rulesSlug: 'president',
        iconCodePoint: Icons.workspace_premium.codePoint,
        cardColorValue: Colors.orange.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 10,
      );

  static GameType belote() => GameType(
        builtinKey: 'belote',
        name: 'Belote',
        rulesSlug: 'belote',
        iconCodePoint: Icons.diamond.codePoint,
        cardColorValue: const Color(0xFF8B4513).toARGB32(), // Brown color
        isLowestScoreWins: false,
        isDefault: true,
        keypadShortcut: KeypadShortcut.value(162),
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 1000,
      );

  static GameType tarot() => GameType(
        builtinKey: 'tarot',
        name: 'Tarot',
        rulesSlug: 'tarot',
        iconCodePoint: Icons.auto_awesome.codePoint,
        cardColorValue: Colors.indigo.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType bridge() => GameType(
        builtinKey: 'bridge',
        name: 'Bridge',
        rulesSlug: 'bridge',
        iconCodePoint: Icons.account_tree.codePoint,
        cardColorValue: Colors.teal.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType rami() => GameType(
        builtinKey: 'rami',
        name: 'Rami',
        rulesSlug: 'rami',
        iconCodePoint: Icons.style_outlined.codePoint,
        cardColorValue: const Color(0xFF9C27B0).toARGB32(), // Deep purple
        isLowestScoreWins: true,
        isDefault: true,
        keypadShortcut: KeypadShortcut.value(100),
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 100,
        gameOverConditionType: GameOverConditionType.lastPlayerOver,
        gameOverThreshold: 100,
      );


  // The long tail, added with schema v14.
  // Generic scoring shapes only: a winning direction and, where the game has a
  // widely known target total, one threshold. No published rulebook is
  // reproduced, and these are game *names* used descriptively.
  // Their rulesets shipped with schema v16 (assets/rules/rules_<locale>.md),
  // which back-fills `rules_slug` on an existing install by builtin key.

  static GameType coinche() => GameType(
        builtinKey: 'coinche',
        name: 'Coinche',
        rulesSlug: 'coinche',
        iconCodePoint: Icons.shield.codePoint,
        cardColorValue: Colors.brown.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 1000,
      );

  static GameType yahtzee() => GameType(
        builtinKey: 'yahtzee',
        name: 'Yahtzee',
        rulesSlug: 'yahtzee',
        iconCodePoint: Icons.casino_outlined.codePoint,
        cardColorValue: Colors.cyan.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType phase10() => GameType(
        builtinKey: 'phase10',
        name: 'Phase 10',
        rulesSlug: 'phase10',
        iconCodePoint: Icons.extension.codePoint,
        cardColorValue: Colors.pink.toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
      );

  static GameType flip7() => GameType(
        builtinKey: 'flip7',
        name: 'Flip 7',
        rulesSlug: 'flip7',
        iconCodePoint: Icons.offline_bolt.codePoint,
        cardColorValue: Colors.lightBlue.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 200,
      );

  static GameType milleBornes() => GameType(
        builtinKey: 'mille_bornes',
        name: 'Mille Bornes',
        rulesSlug: 'mille_bornes',
        iconCodePoint: Icons.rocket_launch.codePoint,
        cardColorValue: Colors.lightGreen.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 5000,
      );

  static GameType rummikub() => GameType(
        builtinKey: 'rummikub',
        name: 'Rummikub',
        rulesSlug: 'rummikub',
        iconCodePoint: Icons.deck.codePoint,
        cardColorValue: Colors.deepOrange.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  // 65, not 66: the box rule stops at 66 bull heads and `over` is strict, so a
  // threshold of 65 puts a player out on exactly 66 (fix/elimination-and-crown,
  // 2026-09-19). As with Uno and Président, no migration rewrites an existing
  // row, which keeps 66: only a new database seeds this value.
  static GameType sixNimmt() => GameType(
        builtinKey: 'six_nimmt',
        name: '6 qui prend',
        rulesSlug: 'six_nimmt',
        iconCodePoint: Icons.local_fire_department.codePoint,
        cardColorValue: const Color(0xFFB71C1C).toARGB32(),
        isLowestScoreWins: true,
        isDefault: true,
        playerDeadConditionType: PlayerDeadConditionType.over,
        playerDeadThreshold: 65,
        gameOverConditionType: GameOverConditionType.lastPlayerOver,
        gameOverThreshold: 65,
      );

  static GameType qwirkle() => GameType(
        builtinKey: 'qwirkle',
        name: 'Qwirkle',
        rulesSlug: 'qwirkle',
        iconCodePoint: Icons.palette.codePoint,
        cardColorValue: Colors.purple.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType farkle() => GameType(
        builtinKey: 'farkle',
        name: 'Farkle',
        rulesSlug: 'farkle',
        iconCodePoint: Icons.stars.codePoint,
        cardColorValue: const Color(0xFFFF8F00).toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 10000,
      );

  static GameType canasta() => GameType(
        builtinKey: 'canasta',
        name: 'Canasta',
        rulesSlug: 'canasta',
        iconCodePoint: Icons.favorite.codePoint,
        cardColorValue: Colors.redAccent.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
        gameOverConditionType: GameOverConditionType.firstPlayerOver,
        gameOverThreshold: 5000,
      );

  static GameType wizard() => GameType(
        builtinKey: 'wizard',
        name: 'Wizard',
        rulesSlug: 'wizard',
        iconCodePoint: Icons.emoji_objects.codePoint,
        cardColorValue: Colors.blueGrey.toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  static GameType triomino() => GameType(
        builtinKey: 'triomino',
        name: 'Triomino',
        rulesSlug: 'triomino',
        iconCodePoint: Icons.change_history.codePoint,
        cardColorValue: const Color(0xFF9E9D24).toARGB32(),
        isLowestScoreWins: false,
        isDefault: true,
      );

  /// The ten types seeded before schema v14, by the literal name they were
  /// seeded with. The v14 migration back-fills [builtinKey] on an existing
  /// install by matching these names, and skips them when it inserts the types
  /// the seed never had — so a type the user deleted stays deleted.
  static const seededNamesBeforeV14 = <String, String>{
    'zapzap': 'ZapZap',
    'uno': 'Uno',
    'scrabble': 'Scrabble',
    'other': 'Autre',
    'skyjo': 'Skyjo',
    'president': 'Président',
    'belote': 'Belote',
    'tarot': 'Tarot',
    'bridge': 'Bridge',
    'rami': 'Rami',
  };

  /// The built-in catalogue, in seed order. **Append only**: the first ten
  /// indices are what an install seeded before v14 already holds.
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
      coinche(),
      yahtzee(),
      phase10(),
      flip7(),
      milleBornes(),
      rummikub(),
      sixNimmt(),
      qwirkle(),
      farkle(),
      canasta(),
      wizard(),
      triomino(),
    ];
  }
}
