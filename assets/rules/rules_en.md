<!--@zapzap-->
Family card game, three or more players. The goal is to hold the lowest total in hand.

## The Principle

In each round, players try to rid their hand of high cards. A player who believes they hold the lowest hand at the table can announce **ZapZap**. This declaration stops the round and forces everyone to reveal their cards.

## Scoring

- **Successful ZapZap** — the caller indeed had the lowest hand: they score **0 points**.
- **Failed or beaten ZapZap** — another player has an equal or lower hand: the caller scores their hand value **plus a penalty of (number of players − 1) × 5 points**.
- **Other players** score their hand value.

Scores accumulate round after round, and you try to stay low.

## Elimination and Rankings

A player is **eliminated as soon as they exceed 100 points**. The final ranking is the reverse of elimination order: the last eliminated finishes first, the first eliminated finishes last.

When only two players remain, the game is played in **golden score**: the loser of the finals receives the score that brings them to exactly 101 points.

## The Rest is Up to Your Table

The details of dealing, drawing, and what you may play vary from group to group. This text describes scoring, which is what the app can do. Use the "Edit" button to add your own house rules.

<!--@uno-->
Fast-paced card game, 2 to 10 players, with a special deck of 108 cards. The goal of a round is to get rid of all your cards before the others.

## Setup

Each player receives **7 cards**. The rest forms the draw pile; the first card is turned over to start the discard pile.

## Gameplay

On your turn, you play a card that matches the top card of the discard pile by **color**, **number**, or **symbol**. Black cards can be played on anything and let you choose the color that follows. If you cannot play, you draw, and play that card if it matches.

Special cards change the course of play: **Skip** skips the next player, **Reverse** changes the direction of play, **+2** makes the next player draw two cards and skip their turn, the **Wild card** lets you choose the color, and the **Wild +4** makes the next player draw four cards.

A player with only one card left must announce **"Uno"**. If they forget and are caught before the next player plays, they draw penalty cards.

## Scoring

The round ends as soon as a player plays their last card. The remaining cards in hand are then counted:

- **Number cards**: their face value;
- **Skip, Reverse, +2**: 20 points each;
- **Wild and Wild +4**: 50 points each.

In the most common rule, the player who finished **collects** the sum of everything left in the others' hands, and the game goes to **500 points**.

Many groups play the opposite: each player scores what remained in their hand as a penalty, and the lowest total wins. This is the version CountScore uses by default. If you play to 500 points, change the game type so the highest score wins.

<!--@scrabble-->
Word game for 2 to 4 players on a 15 × 15 board. You score points by forming words, like in a crossword puzzle.

## Setup

The letters are shuffled face down. Each player draws **7** and keeps them on their rack. The first word must go through the center square.

## Gameplay

On your turn, you place one or more tiles on the same row or column to form a valid word and touch at least one letter already on the board. All words created or extended by your play must be valid. After playing, you draw to bring your rack back to 7 tiles.

A player may also **pass** their turn, or **exchange** tiles with the draw pile if enough remain.

## Scoring

Each letter has a point value; rare letters are worth more, blanks are worth zero.

The order of calculation matters:

1. first apply **double letter** and **triple letter** squares to the tiles played this turn;
2. add up the letters in the word;
3. then apply **double word** and **triple word** squares. Two double-word squares in the same word multiply it by four, two triple-word squares multiply it by nine;
4. all words formed by the play are counted, each separately.

A multiplier square counts **only once**, on the turn it is covered.

Playing all **seven tiles in one turn** earns a bonus of **50 points**, added after multipliers.

## End of Game

The game ends when the draw pile is empty and a player has played their last tile, or when no one can play. Each player deducts the value of their remaining tiles from their score; the player who finished adds the value of what the others kept. The highest score wins.

<!--@skyjo-->
Card game for 2 to 8 players, with a deck of 150 cards numbered **−2 to 12**. The goal is to have the lowest total.

## Setup

Each player receives **12 cards** that they arrange face down in front of them in a **3 by 4 grid**, without looking. Each player then turns over **two** of their choice face up. The rest forms the draw pile; one card is turned over to start the discard pile.

## Gameplay

On your turn, you have two options:

- **take the top card from the discard pile** and exchange it for a card in your grid, face down or face up; the replaced card goes to the discard pile face up;
- **draw** a card: exchange it the same way, or discard it and reveal one of your face-down cards.

Your grid always has twelve spaces; only the number of face-up cards increases.

**Matching column** — if all three cards in a column are face up and have the same value, the entire column is removed and discarded. It counts as zero: the best way to lower your total.

## End of a Round

As soon as a player reveals all **twelve cards**, the round ends: the other players take one more turn, then everyone reveals what remains.

## Scoring

Each player adds up their card values. Negative cards are subtracted, which can give a total below zero. The result is added to the running total from previous rounds.

**The doubling rule**: the player who closed the round sees their round score **doubled** if they don't have strictly the lowest total in that round. Doubling only applies to a positive score — closing with a negative total costs nothing.

## End of Game

The game ends at the end of the round during which a player reaches or exceeds **100 points**. The lowest overall total wins.

<!--@president-->
Card game for 3 to 7 players, with a standard deck of 52 cards. The goal of each round is to get rid of all your cards first to become President.

## Setup

All cards are dealt. The hierarchy runs from 2, the weakest, up to Ace, the strongest — at many tables, the 2 is instead the strongest card, or acts as a wildcard. Agree on this before you start.

## Gameplay

The first player plays a card, or multiple cards of the **same value**. Each following player must play **the same number of cards** of strictly higher value, or pass. When everyone has passed, the trick is closed and the last player to play starts a new trick with any cards they wish.

Four identical cards played or completed often close the trick immediately: this is a **four of a kind**, and many tables reverse the card hierarchy until the end of that trick.

## The Titles

The order in which players get rid of their cards determines the rankings for that round: first is **President**, second is **Vice-President**, last is **Asshole**, second-to-last is **Vice-Asshole**.

In the next round, the titles require an exchange before play: the Asshole gives their **two best cards** to the President, who returns two cards of their choice; the Vice-Asshole and Vice-President exchange one card the same way.

## Scoring

The President often keeps score, but rarely the same way twice. The most common scoring gives 2 points to the President and 1 to the Vice-President, or 3, 2, and 1 to the top three.

Another common approach, easier to track on paper, is to give a penalty point to the last-place finisher each round and eliminate whoever accumulates too many. This is what CountScore uses by default, with the lowest score winning and the game ending above **11 points**. If your group scores the other way, change the score direction in your game type settings.

<!--@belote-->
Trick-taking game for four, in two teams of two, with a 32-card deck. The goal is to be the first team to reach an agreed total, usually **1,000 points**.

## Card Order

It changes by suit:

- **In trump**: Jack (20), 9 (14), Ace (11), 10 (10), King (4), Queen (3), 8 and 7 (0);
- **In non-trump suits**: Ace (11), 10 (10), King (4), Queen (3), Jack (2), 9, 8 and 7 (0).

The Jack and 9 of trump are therefore the two strongest cards in the game.

## The Bid

Five cards are dealt to each player, then one card is turned over. Each player can **bid** that suit as trump. If no one accepts on the first round, you go again and offer to choose a different suit. The team that bids becomes the **bidding team** and must make their contract.

## Gameplay

You must follow suit. If you cannot, you must **trump** if the opponent is winning the trick, and **overtrump** if a lower trump is already played. Your partner, if they are already winning the trick, releases you from trumping.

## Scoring

Each deal is worth **162 points**: 152 points in card values and **10 points for the last trick**, the *dix de der*.

- The bidding team makes their contract if they score over **81 points**. Each team then scores what they collected.
- If they don't reach 81, they are **down**: they score zero and the opposing team gets all 162 points.
- **Belote and rebelote** — declaring the King and Queen of trump when playing them earns an extra **20 points**. This bonus is kept even if the contract fails.
- **Capot** (or sweep) — winning all eight tricks earns a preset bonus, often 90 or 100 points.

## End of Game

You add up deals until one team reaches the target total. The team with the higher score wins.

<!--@tarot-->
Contract trick-taking game for 3 to 5 players, with a **78-card deck**: four suits of 14 cards, 21 trumps, and the Excuse. One player, the **taker**, plays alone against the others.

## The Bouts (Oudlers)

Three trump cards count double in the scoring and set the contract requirement: the **21**, the **Petit** (trump 1), and the **Excuse**. These are called the **bouts** (or oudlers).

## The Contracts

After the deal, each player bids or passes. From least to most ambitious: **Petite** (or Prise), **Garde**, **Garde sans** (Guard without), **Garde contre** (Guard against). The first two contracts let the taker take the *chien* (dog)—the cards set aside during the deal—and discard the same number; the last two do not.

With five players, the taker **calls a King** before play begins: whoever holds it becomes their partner, but keeps it secret.

## Gameplay

You must follow suit; if you cannot, you must **play trump**, and beat the highest trump already played if you can. The Excuse never wins a trick but remains with the player who played it.

## Scoring

Cards are counted in pairs: King 4.5 · Queen 3.5 · Knight 2.5 · Jack 1.5 · others 0.5 each. The bouts are worth 4.5 each.

The taker must reach a threshold that depends on the **number of bouts** they captured:

| Bouts | Points to Reach |
|---|---|
| 0 | 56 |
| 1 | 51 |
| 2 | 41 |
| 3 | 36 |

The difference from that threshold, plus a base of 25 points, is **multiplied by the contract**: ×1 for Petite, ×2 for Garde, ×4 for Garde sans, ×6 for Garde contre.

The **Petit au bout** (Petit on the last trick) is worth 10 points, multiplied the same way. The **handful** and the **slam** add their own bonuses.

## End of Game

The taker wins or loses their score, and the defenders score the opposite. Scores accumulate over as many deals as you wish; the highest total wins.

<!--@bridge-->
Contract trick-taking game for four, in two teams of two, with a standard deck of 52 cards. Each deal is played in two phases: **bidding**, then **card play**.

## Bidding

Each player in turn bids a contract, passes, doubles, or redoubles. A bid indicates a **level** and a **suit** (or *No Trump*). The level counts **above six tricks**: a bid of 3 No Trump commits you to make 6 + 3 = **9 tricks** out of 13.

Bidding ends after three consecutive passes. The last bid becomes the contract for that deal, and the player who first named that suit in their partnership is the **declarer**. Their partner lays down their hand: this is the **dummy**.

## Card Play

You must follow suit. If you cannot, you may play any card, including trump. The trick goes to the highest trump played, or if no trump, the highest card of the suit led.

## Scoring

Only the tricks **bid for** count below the line:

- **20 points** per trick in Clubs or Diamonds;
- **30 points** per trick in Hearts or Spades;
- **40 points** for the first No Trump trick, then 30 per subsequent trick.

A contract reaching **100 points** is a **game** (manche); it earns a bonus of **300 points** if the team is not vulnerable, **500** if it is. Below that, a made contract earns a smaller part-game bonus. Tricks made over the contract are counted as a bonus but do not count toward game.

A **failed** contract awards points to the opposing team based on how many tricks were missed, vulnerability, and whether the contract was doubled.

The **small slam** (12 tricks bid) and the **grand slam** (all 13) add substantial bonuses.

## Two Scoring Formats

In **rubber** (robre), you play until one team wins two games. In **tournament**, each deal is scored separately and compared across tables. CountScore simply adds up the deals: the highest total wins.

<!--@rami-->
Combination game for 2 to 6 players, with two standard decks plus their jokers. The goal is to lay down all your cards in combinations and discard your last card.

## Setup

Each player receives **13 or 14 cards** depending on your group's preference. The rest forms the draw pile; one card is turned over to start the discard pile.

## Combinations

- **A run**: at least three cards in sequence of the same suit.
- **A set**: three or four cards of the same value, in different suits.

A **joker** replaces any card and takes its value in the combination.

## Gameplay

On your turn, you draw a card—from the pile or the discard—then discard a card. Between these actions, you may lay down combinations on the table and add to combinations already there.

**Your opening meld** is constrained: you can only open with a set of combinations totaling at least **51 points**, and usually not before your second turn.

## Card Values

Cards 2 through 10 are worth their face value. Jack, Queen, and King are worth **10**. Ace is worth **11** when it follows the King in a run or set, and **1** when it opens a run before the 2.

## Scoring

The round ends as soon as a player has laid down all their cards. The other players then count what remains in their hand as a **penalty**:

- unmelded cards, at their point value;
- a **joker** left in hand: **20 points**;
- a player who **has not melded anything** often receives a flat penalty of **100 points**.

Penalties accumulate round after round, and you try to stay low.

## End of Game

A player is **eliminated as soon as they exceed 100 points**. The game continues among the survivors; the last player standing, or the lowest total, wins. Many groups play to 200 or 500 points: adjust the threshold in your game type settings.
