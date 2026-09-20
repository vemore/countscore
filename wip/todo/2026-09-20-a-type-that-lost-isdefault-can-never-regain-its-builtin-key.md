# Un type qui a perdu `isDefault` ne peut plus jamais retrouver son `builtin_key`, donc jamais ses règles

- **Noted:** 2026-09-20 — test sur appareil de 1.4.0+8 avant publication, sur la base réelle du propriétaire
- **Theme:** game-types
- **Area:** app
- **Blocks release:** yes — perte de données déjà subie sur la seule installation de production, et le pas v18 ne la répare pas

## Constaté, sur l'appareil, après la v18

1.4.0+8 installé en place sur le Pixel (base passée de v17 à v18, toutes les parties intactes) :
*Types de jeux → 6 qui prend → Règles du jeu* affiche toujours **« Pas encore de règles »**.

ZapZap, lui, affiche bien ses règles — mais **pas grâce à la migration**. La PWA a pris le pas
v18 le 2026-09-20 à 13:56 UTC, a réparé son `rules_slug` local et l'a poussé par-dessus le NULL
du serveur (`game_types.updated_at = 13:56:39`, groupe `66ab3488`, vérifié en base de
production) ; le téléphone l'a tiré. La réparation locale n'a rien fait sur ce type non plus.

## Les lignes hors d'atteinte

Export de la base du propriétaire, 23 types vivants. **Trois n'ont aucun `builtin_key`** :

| id | nom | `builtin_key` | `rules_slug` | `isDefault` | parties vivantes |
|---|---|---|---|---|---|
| 6 | Skyjo | NULL | NULL | 0 | 5 |
| 7 | Yam's | NULL | NULL | 0 | 0 |
| 8 | 6 qui prend | NULL | NULL | 0 | 7 |

Les vingt autres ont leur clé **et** leur slug. Les trois partagent le `created_at` des autres
semences (`1788935555660`) : ce sont des lignes **semées par l'app**, pas des types créés par
l'utilisateur. Leurs colonnes de score le confirment — `6 qui prend` est `isLowestScoreWins=1`,
`playerDeadConditionType='over'`, `playerDeadThreshold=66`, `gameOverThreshold=66`, exactement
la définition intégrée de `six_nimmt`.

`applyV16` — que `applyV18` rejoue — filtre `WHERE builtin_key = ? AND rules_slug IS NULL`. Une
ligne sans clé n'est jamais touchée, quel que soit le nombre de fois qu'on rejoue le pas.

## Le mécanisme, et ce que l'entrée précédente a conclu à tort

Les back-fills de **clé** sont keyés sur `isDefault` :

- `applyV13` (`sync_schema.dart:243`) : `WHERE isDefault = 1 AND rules_slug IS NULL AND name = ?`
- le back-fill de clé de v14 (`:293`) : même forme.

L'éditeur d'avant 1.3.1 écrivait `isDefault = 0` à chaque enregistrement
([[2026-09-20-editing-a-game-type-erases-its-rules]], corrigé par #179). Une ligne éditée
**avant** que ces back-fills ne tournent a donc raté l'attribution de sa clé — définitivement,
puisqu'une migration ne tourne qu'une fois. Et sans clé, elle rate aussi toute réparation de
slug, y compris la v18.

`seededNamesBeforeV14` n'a par ailleurs que dix entrées (`zapzap`, `uno`, `scrabble`, `other`,
`skyjo`, `president`, `belote`, `tarot`, `bridge`, `rami`) : `Yam's` et `6 qui prend` n'y
figurent pas du tout, donc même avec `isDefault = 1` ils n'auraient pas été keyés par le nom.

[[2026-09-20-wiped-rules-slug-is-never-restored]] a tranché qu'`isDefault` était « un drapeau
que rien ne lit » et que `builtin_key` « survit à une édition : seul un vrai renommage le
lâche ». Les deux affirmations sont fausses sur la base réelle : deux migrations lisent
`isDefault`, et trois lignes ont perdu leur clé sans avoir jamais été renommées. La conclusion
« le pas v18 suffit » en découlait.

**Fix:** un pas **v19** qui ré-attribue `builtin_key` aux lignes qui l'ont perdue, puis rejoue
la garniture de slug. Le point difficile est de ne pas keyer un vrai type perso qui porterait
le même nom. Indices disponibles, à combiner plutôt qu'à prendre isolément :

- le **nom** comparé aux noms intégrés **des dix locales** (pas seulement `seededNamesBeforeV14`,
  qui est à la fois trop court et monolingue) ;
- les **colonnes de score** (`_scoringColumns`) égales à la définition intégrée — deux lignes qui
  s'accordent dessus jouent le même jeu ;
- le `created_at` égal à celui des autres lignes semées de la même base.

À trancher explicitement dans l'implémentation : ce qu'on fait d'une ligne qui matche le nom
mais pas le score (un utilisateur qui a changé le seuil de son « Skyjo »), et si le pas doit
aussi remettre `isDefault`.

**Acceptance:**

- Après la migration, une ligne semée sans `builtin_key` dont le nom et les colonnes de score
  correspondent à un type intégré retrouve sa clé **et** son `rules_slug`, sur les deux moteurs.
- Un type réellement créé par l'utilisateur, même homonyme d'un type intégré, garde `builtin_key`
  NULL et n'acquiert aucun slug.
- Un type intégré **renommé** par l'utilisateur reste sans clé (le renommage est un choix).
- Un `rules` écrit à la main n'est jamais touché.
- Un test de migration v18 → v19 couvre les quatre cas, à côté de `test/migration_v17_to_v18_test.dart`.
- Sur une copie de la base réelle du propriétaire, `Skyjo`, `6 qui prend` et `Yam's` réaffichent
  leur jeu de règles.

**Lane B** (échec silencieux, données persistées) : revue indépendante avant la fusion,
`.llmwiki/ParallelDelivery.md`.
