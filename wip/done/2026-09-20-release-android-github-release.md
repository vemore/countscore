# release-android §10 ne publie jamais la release GitHub du tag

**Status:** done (2026-09-20) — closed by docs/execution-lanes. `release-android` §10 now
publishes the release with `gh release create`, without `--target` and with no asset, says why
no AAB or APK is attached (`.llmwiki/Release.md` § Developer verification), and the checklist
has a line for it; `Release.md` § Tags records that every tag from `1.2.0+5` on carries such a
release, and its § Decisions the 2026-09-20 hand-made `1.3.0+6` one.

- **Noted:** 2026-09-20 — en publiant après coup la release GitHub 1.3.0, oubliée à la livraison
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

`.claude/skills/release-android/SKILL.md` §10 « After the rollout » demande de taguer le commit
livré, puis enchaîne sur `.llmwiki/Release.md` et le ménage des worktrees. Ni la section ni la
checklist finale ne mentionnent `gh release`, et aucune autre page ne couvre l'étape —
`grep -rn "gh release" .claude/skills/ .llmwiki/` ne renvoie rien.

Conséquence observée : les sept versions `1.0.0+1` → `1.3.0+6` ont toutes leur tag sur `origin`,
mais `gh release list` s'arrêtait à `1.2.0+5`. La release `1.3.0+6` a été créée à la main le
2026-09-20, un jour après la mise en production, parce que l'utilisateur l'a remarqué.

**Fix:** ajouter à §10, juste après la puce du tag, la commande qui publie la release à partir
des notes déjà écrites pour le Play Store, et la ligne correspondante dans la checklist :

```bash
gh release create <x.y.z+n> --title "<x.y.z+n>" \
  --notes-file store_listing/en-US/release_notes_v<x.y.z>.txt
```

Sans `--target` : le tag est déjà poussé et `main` a souvent avancé depuis, la release doit
rester sur le commit tagué. Et **sans pièce jointe** : `.llmwiki/Release.md` explique que la clé
d'upload n'est délibérément pas enregistrée chez Google, donc un APK distribué hors Play serait
refusé à l'installation sur les appareils certifiés de certains pays. Le skill doit le dire, pour
que personne n'ajoute un AAB « tant qu'on y est ».

**Acceptance:**
- §10 contient la commande `gh release create`, sans `--target` et sans asset.
- La checklist de `release-android` a une ligne « release GitHub publiée pour le tag ».
- Le skill énonce pourquoi aucun AAB/APK n'est attaché, en renvoyant à `.llmwiki/Release.md`.
