# The win direction can be flipped on a type that already has finished games, reversing every past standing

**Status:** done (2026-09-20) — closed by fix/game-type-editor. The user answered the open question with the confirmation rather than a read-only switch: flipping the direction on a type with at least one **finished** game asks first, naming the count (`countFinishedGames`), and cancelling leaves the row untouched; a type with no finished game saves with no interruption. The contradiction between the direction and a *Premier joueur à atteindre* condition is a line under the switch, never a refusal.

- **Noted:** 2026-09-20 — reviewing the game-type editor at the user's request
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`isLowestScoreWins` is a plain `SwitchListTile` in the editor
(`lib/screens/game_types_screen.dart:231`) and is written straight to the row. It is also the
*only* input to `GameStanding.ranks` (`lib/models/game_standing.dart:52`), which is read for
every standing the app ever shows — including games finished months ago, since a standing is
recomputed from the scores each time, never stored.

Flipping the switch therefore rewrites history: the winner of every past game of that type
becomes the loser, on the home list's cards, the ranking, the end screen, the shared image and
the player statistics. Nothing warns, and nothing can undo it but flipping back.

The codebase already knows this is the dangerous move. `lib/models/game_type.dart:235`, on Uno
and Président changing direction: *"no migration flips an existing row: a type that already has
games would see its finished standings reversed"*. The seeds were protected; the editor was
not.

The same switch can also be set against the type's own conditions — *lowest score wins*
together with *Premier joueur à atteindre 500* — and nothing notices.

**Fix:** when the switch is flipped on a type that has at least one **finished** game, say so
before saving: how many games, and that their standings will be reversed. An open game is not
at risk in the same way and does not need the warning. A second, smaller guard: flag the
contradiction between a win direction and a game-over condition that pulls the other way — a
line under the switch, not a refusal, since a house rule may want it.

**Acceptance:**
- Flipping the direction on a type with finished games asks first, naming the count; cancelling leaves the row untouched.
- Flipping it on a type with no finished game saves with no interruption.
- Choosing *lowest score wins* with *first player to reach* shows the contradiction without blocking the save.

**Open question:** should the warning be a confirmation, or should the direction simply become
read-only once a game of that type is finished, with a "duplicate this type" way out?
