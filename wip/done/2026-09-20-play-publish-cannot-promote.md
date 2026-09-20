# `play_publish.py` ne sait pas promouvoir une version d'une piste à une autre

**Status:** done (2026-09-20) — closed by feat/play-publish-promote. `publish --promote`
référence un build que Play détient déjà, sans le reconstruire ni le re-téléverser.

- **Noted:** 2026-09-20 — en voulant passer 1.3.1+7 d'internal à production après le test sur appareil
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no — mais il a bloqué la mise en production de 1.3.1 le jour même

Deux murs se sont dressés sur le parcours normal *internal → production* :

1. **Le garde-fou de version.** `cmd_publish` refusait tout `versionCode` qui ne soit pas
   strictement supérieur au plus haut de **toutes** les pistes. Or la version qu'on promeut est
   précisément déjà sur internal, donc elle échouait contre elle-même :
   `versionCode 7 is not above 7, already on track 'internal'`.
2. **Le téléversement systématique.** Même le garde-fou levé, `cmd_publish` appelait toujours
   `edits.bundles().upload()`. Play refuse un `versionCode` qu'il a déjà vu, donc la promotion
   aurait échoué côté serveur. Une promotion doit **référencer** le build, pas le renvoyer.

Conséquence observée : la seule issue était la Play Console à la main, ce que
`references/play-console-handoff.md` règle 2 interdit pour tout ce que l'API couvre — et elle
couvre bien les pistes.

**Fix retenu:** `publish --promote`, qui saute le téléversement et remplace le garde-fou par
deux refus plus justes — le code n'est sur aucune piste (rien à promouvoir), ou il est déjà sur
la piste visée (rien à faire). `verify_aab.sh` n'est pas rejoué : le bundle a été vérifié quand
il a été publié, et il n'y a plus de bundle local à vérifier. Le message du garde-fou d'origine
pointe désormais vers `--promote`.

**Acceptance:**
- `publish --track production --promote --rollout 0.2` ne fait aucun `edits.bundles.upload`. ✓
- Promouvoir un code absent de toutes les pistes est refusé. ✓
- Promouvoir vers une piste qui le porte déjà est refusé. ✓
- `--promote --aab <path>` est refusé : il n'y a pas de bundle à désigner. ✓
- Le refus « not above » nomme `--promote` comme issue. ✓
