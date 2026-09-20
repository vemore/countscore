# Un `rules_slug` NULL voyage dans la synchronisation et défait la réparation v18

**Status:** done (2026-09-20) — closed by fix/rules-slug-payload. La poussée omet la clé
`rules_slug` quand la valeur locale est NULL, une valeur NULL tirée n'efface plus un slug
local posé, et un type intégré reçu sans slug est inséré avec celui dérivé de son
`builtin_key`. Cinq tests dans `test/sync/sync_store_test.dart` ; la règle et
l'alternative écartée sont dans [[Sync]] et [[SchemaV10]]. Aucun changement de serveur.

- **Noted:** 2026-09-20 — revue indépendante de #192 (`fix/rules-slug-restore`), puis requête directe sur la base de production
- **Theme:** game-types
- **Area:** app
- **Blocks release:** yes — perte de données déjà subie sur la seule installation de production, et la réparation n'est pas durable : le NULL corrompu est sur le serveur maintenant, et aucune migration ne repassera jamais

## Constaté

`2026-09-20-wiped-rules-slug-is-never-restored` ajoute un pas v18 qui rejoue `applyV16` et
remplit les `rules_slug` vidés par l'ancien éditeur. La réparation est locale, et elle ne
tient pas : le NULL circule.

1. **La poussée envoie le NULL.** `lib/services/sync/sync_store.dart:458` met *toujours* une
   clé `rules_slug` dans la charge utile `game_type`, NULL compris.
2. **Le serveur garde le NULL.** `_client_payload` filtre sur la *présence* de la clé, pas sur
   sa valeur (`backend/app/routes/sync.py:119-122`), et `_logged_payload` (`:409`) journalise
   ce que les autres appareils tirent. `_apply_delta` fait `setattr(obj, key, value)` : la
   colonne du serveur passe à NULL.
3. **La tirée le réécrit en local.** `_applyGameType` :
   `if (p.containsKey('rules_slug')) 'rules_slug': p['rules_slug']` (`sync_store.dart:748`).

Donc un appareil encore corrompu pousse son NULL, et un appareil que v18 vient de réparer le
réécrit à la tirée suivante — sans qu'aucune migration ne puisse plus rien y faire.

**Ce n'est pas une hypothèse.** Requête directe sur la base de production :

- 8 groupes, 14 appareils.
- Groupe `66ab3488-4d2e-4eff-9ba7-3235476d8eff` — créé le 2026-09-14, **4 appareils, vus pour
  la dernière fois le 2026-09-20 12:55 UTC** — porte une ligne `game_types`
  `name='ZapZap'`, `builtin_key='zapzap'`, **`rules_slug` NULL**, non supprimée.
- L'autre groupe qui a un type ZapZap (`e802033b`, 1 appareil, vu le 2026-09-19) a
  `rules_slug='zapzap'` — correct.

Le NULL corrompu est donc sur le serveur, dans le groupe que le propriétaire utilise, et c'est
la valeur qui sera rendue.

**Fix:** trois lignes dans `sync_store.dart`, côté client seulement — aucun changement de
serveur, aucun changement de schéma.

1. **Poussée** : n'envoyer `rules_slug` que s'il est non NULL. La clé absente veut dire « pas
   d'avis », et le groupe garde le slug qu'un appareil sain lui a donné.
2. **Tirée, mise à jour** : un `rules_slug` NULL entrant n'écrase pas un slug local posé.
   Seule cette colonne change de règle : `rules`, lui, se vide volontairement
   (*Restaurer la valeur par défaut*, `game_rules_screen.dart`), donc il garde la sémantique
   `containsKey`.
3. **Tirée, insertion** : un type intégré qui arrive avec un slug NULL et un `builtin_key`
   connu est inséré avec `defaultRulesSlugs[builtin_key]` — la même dérivation qu'`applyV16`,
   importée et non recopiée. Sans ça, un appareil qui rejoint le groupe avant qu'un appareil
   réparé n'ait poussé insérerait le NULL et ne serait plus jamais réparé.

**Alternative écartée :** retirer `rules_slug` de la charge utile et le recalculer à la
réception depuis `builtin_key`. C'est ce que pesait l'entrée `wiped-rules-slug` : ça rendrait
la corruption non contagieuse, mais c'est un changement de contrat entre appareils, et un type
**renommé** par l'utilisateur perd son `builtin_key` (`isBuiltinRename`,
`lib/utils/game_type_name.dart:149`) — le slug est alors la seule chose qui porte ses règles
d'un appareil à l'autre. Le correctif étroit garde ce cas.

**Guérison du serveur :** rien de nouveau n'est nécessaire. Le `UPDATE` de v18 sur une ligne
liée déclenche le trigger de capture (`_capture`, `sync_schema.dart`), qui met une ligne dans
`outbox` ; la poussée suivante envoie `rules_slug='zapzap'`, non NULL, et le serveur du groupe
`66ab3488` est réparé par l'appareil du propriétaire lui-même.

**Acceptance:**

- Une charge utile `game_type` tirée sans valeur pour `rules_slug` (NULL) laisse intact le
  slug de la ligne locale.
- Un `rules_slug` non NULL tiré écrase toujours le slug local — le partage de règles continue
  de marcher, renommages compris.
- Une ligne locale dont le `rules_slug` est NULL est poussée *sans* la clé `rules_slug`.
- Un type intégré tiré avec `builtin_key` connu et slug NULL est inséré avec le slug dérivé.
- `rules` garde la sémantique `containsKey` : un `rules` NULL tiré vide bien le `rules` local.
