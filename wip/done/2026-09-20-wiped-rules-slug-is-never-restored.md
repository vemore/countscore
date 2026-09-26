# Les `rules_slug` effacés par l'ancien éditeur ne sont jamais restaurés, alors qu'une reprise existe déjà

**Status:** done (2026-09-20) — closed by fix/rules-slug-restore. Le schéma passe en **v18** (`lib/services/drift/database.dart`, `lib/services/database_service.dart`) et le pas v18, `applyV18` (`lib/services/sync/sync_schema.dart`), **est** `applyV16` : aucune logique nouvelle, seulement la deuxième exécution qui manquait. Les deux moteurs le lancent (chaîne sqflite sur natif, `onUpgrade` de Drift sur web). Le sort d'`isDefault` est tranché et écrit : colonne **historique**, que rien ne lit et sur laquelle plus aucune migration, requête ou écran ne branche — `builtin_key` est la seule identité d'un type intégré. Elle n'est ni supprimée (réécrire `game_types` chez tout le monde pour rien) ni retirée de la charge utile (changement de contrat sans bénéfice), et v18 ne la restaure pas. Documenté dans [[Schema]] (section `game_types.isDefault`, ligne v18 de l'historique, deux décisions), dans [[Sync]] et sur le champ lui-même (`lib/models/game_type.dart`). `test/migration_v17_to_v18_test.dart` couvre les quatre critères. Le `rules` écrit à la main que le bug a effacé reste irrécupérable : c'est du contenu utilisateur sans seconde source. La question de la charge utile `rules_slug` n'a pas eu à être ouverte : le pas v18 tient sans y toucher.

- **Noted:** 2026-09-20 — test sur appareil de 1.3.1+7, ZapZap et 6 qui prend affichent « Pas encore de règles » sur le Pixel du propriétaire
- **Theme:** game-types
- **Area:** app
- **Blocks release:** yes — perte de données déjà subie sur la seule installation de production, et la reprise tient en une ligne

## Constaté

Sur le Pixel, après la mise à jour en 1.3.1 : *Types de jeux → ZapZap → Règles du jeu* affiche
**« Pas encore de règles »** avec *Écrire les règles*, au lieu du jeu de règles livré. Idem pour
**6 qui prend**. Les deux gardent pourtant leur `builtin_key` — ils sont toujours nommés et
iconés comme des types intégrés, et leur bandeau « DANS COUNTSCORE » est correct.

Cause : l'éditeur d'avant 1.3.1 reconstruisait la ligne à partir des seuls champs du
formulaire, écrivant `rules`, `rules_slug` et `isDefault` en NULL/0 à chaque enregistrement
([[2026-09-20-editing-a-game-type-erases-its-rules]], corrigée par #179). #179 empêche que ça
se reproduise ; **rien ne répare ce qui est déjà perdu**. Et comme `rules_slug` voyage dans la
synchronisation (`lib/services/sync/sync_store.dart:458`, `:806`), le NULL est parti dans le
groupe.

## La reprise existe déjà — et l'entrée d'origine s'est trompée sur ce point

`2026-09-20-editing-a-game-type-erases-its-rules` affirmait que « le dégât survit à
l'édition », parce que les back-fills ciblent `WHERE isDefault = 1 AND rules_slug IS NULL`.
C'est vrai de **`applyV13`** (`lib/services/sync/sync_schema.dart:243`) et du back-fill de clé
de v14 (`:293`). Ce n'est **pas** vrai d'**`applyV16`** (`:376-383`) :

```sql
UPDATE game_types SET rules_slug = ? WHERE builtin_key = ? AND rules_slug IS NULL
```

Aucune mention d'`isDefault`, et la boucle couvre les **21** entrées de `defaultRulesSlugs`
(`:183-205`), ZapZap et six_nimmt compris — pas seulement les douze types de v14 que son
dartdoc met en avant. Or `builtin_key` **survit** à une édition : seul un vrai renommage le
lâche (`isBuiltinRename`, `lib/utils/game_type_name.dart:149`).

Donc rejouer `applyV16` répare toutes les lignes touchées, sur les deux moteurs, sans une
ligne de logique nouvelle. La seule raison pour laquelle ça n'arrive pas est que la migration
ne tourne qu'une fois : `lib/services/drift/database.dart:76` l'appelle sous `if (from < 16)`,
et la base du propriétaire est en v17.

## Ce qu'il faut clarifier : à quoi sert `isDefault` ?

En cherchant la reprise, `isDefault` s'est révélé être un drapeau que **rien ne lit** :

| Endroit | Ce qu'il en fait |
|---|---|
| `sync_schema.dart:243`, `:293` | deux migrations historiques, déjà passées partout |
| `sync_store.dart:449` | **poussé** au serveur comme `is_default` |
| `sync_store.dart:801` | une ligne **reçue** est insérée avec `isDefault: 0`, la valeur poussée est jetée |
| `game_type.dart`, `tables.dart`, `database_service.dart` | la colonne, sa valeur par défaut, et `isDefault: true` sur les semences |

Aucune décision d'exécution ne le consulte. Et la ligne `:801` a une conséquence qu'il faut
énoncer : **un type intégré arrivé par le groupe a `isDefault = 0` depuis toujours**, donc il
était déjà invisible aux back-fills en `isDefault = 1` bien avant le bug de l'éditeur. Le
drapeau ne distingue pas « semé par l'app » de « écrit par l'utilisateur » dès qu'un groupe
existe — c'est `builtin_key` qui le fait, et lui seul.

**Fix:** en deux temps qui peuvent tenir dans la même pull request :

1. **Un pas v18 qui rejoue `applyV16`.** Idempotent par construction (il ne touche que les
   `rules_slug IS NULL`), il ne ressuscite rien (aucun INSERT), et aucun chemin utilisateur ne
   vide `rules_slug` volontairement — *Restaurer la valeur par défaut*
   (`game_rules_screen.dart:83-89`) vide `rules`, pas le slug. Rejouer est donc sûr.
2. **Trancher le sort d'`isDefault`.** Soit on lui donne un sens tenable et on le documente
   dans [[Schema]], soit on le retire du modèle et de la charge de synchronisation. Ne pas
   laisser une colonne que le code écrit, envoie, jette à la réception, et dont une entrée a
   déduit à tort qu'une perte était irréparable.

**Acceptance:**

- Après la migration, une base où `rules_slug` a été vidé sur une ligne qui garde son
  `builtin_key` réaffiche le jeu de règles livré, sur mobile et sur le web.
- Une ligne sans `builtin_key` (type créé ou renommé par l'utilisateur) reste intacte.
- Un `rules` écrit à la main n'est pas touché — seul le slug est rempli.
- Un test de migration v17 → v18 couvre les trois cas, à côté de `test/migration_v16_to_v17_test.dart`.
- Le sort d'`isDefault` est écrit quelque part : soit son sens dans [[Schema]], soit sa
  suppression.

**Décidé (2026-09-20, refinement) :** la question de la charge utile se tranche en
l'implémentant, et **ne fait pas partie de cette entrée**. Réparer les données perdues est ce
qui bloque la livraison ; retirer `rules_slug` de la synchronisation est un changement de
contrat entre appareils, qui mérite sa propre entrée et ses propres critères. Si
l'implémentation montre que le pas v18 ne tient pas sans y toucher, elle ouvre l'entrée
correspondante plutôt que d'élargir celle-ci.

Ce qu'il faudra y peser, pour ne pas le redécouvrir : `rules_slug` est dérivable de
`builtin_key` — c'est exactement ce que fait `applyV16` — donc le retirer de la charge utile
rendrait la corruption non contagieuse, au prix d'un slug recalculé à la réception. Mais un
type **renommé** par l'utilisateur perd son `builtin_key` (`isBuiltinRename`,
`lib/utils/game_type_name.dart:149`), et le slug devient alors la seule chose qui porte ses
règles d'un appareil à l'autre.
