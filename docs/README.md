# `docs/` — the published privacy policy

This directory exists for one reason: Google Play requires a **permanent, public HTTPS URL**
for the privacy policy, and the Data Safety declaration is only valid while the page at that
URL says what the app actually does.

`privacy-policy.html` is served by GitHub Pages at

    https://vemore.github.io/countscore/privacy-policy.html

which is the URL recorded in `PLAY_STORE_DATA_SAFETY.md`.

## It is generated — do not edit it by hand

The page is rendered from `privacy_policy.md` at the repository root, which is the single
source of truth. After changing the policy, regenerate and commit both files together:

```bash
python3 scripts/build_privacy_page.py    # needs pandoc on PATH
```

Editing the HTML directly would let the published policy and the repository policy say
different things — which is exactly the drift that left `PUBLISHING.md` contradicting both
compliance documents for ten months. A policy that disagrees with the declaration is a Play
policy violation, not a documentation nit.

## Enabling Pages

One manual step, in the repository settings, done once:

**Settings → Pages → Source: Deploy from a branch → Branch: `main`, folder: `/docs`**

Then load the URL in a private window to confirm it is public and needs no login.

## What is *not* here

Project documentation lives elsewhere and is not published: `.llmwiki/` for durable
knowledge, `.claude/skills/` for procedures, `README.md` for newcomers. Anything added to
this directory becomes publicly served, so put nothing here that is not meant to be read by
anyone.
