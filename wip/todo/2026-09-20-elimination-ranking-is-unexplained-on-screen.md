# Le classement par élimination affiche des places qui contredisent les totaux, sans rien expliquer

- **Noted:** 2026-09-20 — test sur appareil de 1.3.1+7 avant la mise en production, partie réelle p172
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no — le comportement est celui qui a été décidé ; c'est sa lisibilité qui manque

Depuis `feat/ranking-rule` (#181), une partie **terminée** d'un type qui élimine *et* se finit
au dernier joueur en jeu se classe par ordre d'élimination inversé. C'est exactement ce que
l'entrée demandait. Mais à l'écran, rien ne le dit.

**Constaté** sur la partie p172 du propriétaire (ZapZap, le plus petit score gagne) :

| Place | Joueur | Total |
|---|---|---|
| 1 | Vincent | 98 |
| 2 | Guillaume | 101 |
| 3 | Laurent | 130 |
| 4 | Lionel | 132 |
| **5** | **Thibaut** | **109** |

Thibaut est dernier avec 109 alors que Lionel est 4e avec 132, dans un jeu où le plus petit
score gagne. C'est correct — Thibaut est sorti au tour 6, Lionel au tour 9 — mais l'écran des
résultats, le podium et les badges `#n` du plateau affichent tous des places qui, lues seules,
passent pour un bug. Le podium est le pire cas : il met Laurent (130) sur la 3e marche à côté
de totaux plus petits.

Le seul endroit qui l'explique est l'analyse LLM, qui titre d'elle-même « Classement final par
ordre d'élimination inversé » — une fonction optionnelle, qui demande un serveur.

**Fix:** dire la règle là où elle s'applique. Des pistes, à trancher :
- une ligne sous `rankingSummary` sur l'écran des résultats quand
  `standing.rule == RankingRule.eliminationOrder`, du genre « classement à l'ordre
  d'élimination : le dernier éliminé devant » ;
- le tour de sortie sur chaque ligne éliminée (« sorti au tour 6 »), qui rend l'ordre évident
  sans phrase ;
- rien sur le plateau tant que la partie est ouverte — elle s'y classe au score, et c'est déjà
  cohérent.

**Acceptance:**
- Sur une partie terminée classée à l'élimination, l'écran des résultats dit pourquoi l'ordre
  n'est pas celui des totaux.
- Une partie classée au score n'affiche aucune de ces mentions (pas de bruit sur les 19 autres types).
- Un test couvre les deux états, et les badges `#n` du plateau sont inchangés.

**Décidé (2026-09-20, refinement) :** l'écran des résultats seulement. Le plateau garde ses
badges au score et ne change pas : une partie ouverte s'y classe au total, ce qui est déjà
cohérent, et la règle d'élimination ne s'applique qu'à une partie **terminée**. Expliquer la
règle là où elle ne s'applique pas encore ajouterait du bruit sur les vingt types.
