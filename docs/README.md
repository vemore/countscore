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
python3 scripts/build_privacy_page.py            # needs pandoc on PATH
python3 scripts/build_privacy_page.py --check    # what CI runs; writes nothing
```

The page is rendered with pandoc **3.6.4**, the version CI installs (pinned by checksum in
`.github/workflows/ci.yml`) and `PANDOC_VERSION` in the script. Another version can render
the same Markdown differently: render with 3.6.4 (a release archive from
github.com/jgm/pandoc is enough), or `--check` warns and the diff may be noise. Moving the pin
moves all three at once, with the page regenerated in the same commit.

CI refuses, in the `Backend — ruff, mypy, pytest` job, a pull request that

- changes `privacy_policy.md` without regenerating this page, or edits the page by hand;
- changes `privacy_policy.md` without changing its `**Last Updated**` line — date the
  change and add a Version History entry.

Editing the HTML directly would let the published policy and the repository policy say
different things — which is exactly the drift that left `PUBLISHING.md` contradicting both
compliance documents for ten months. A policy that disagrees with the declaration is a Play
policy violation, not a documentation nit.

## How it is published

Since 2026-09-19 the page is published by `.github/workflows/deploy-pages.yml`, together with
the PWA (the Pages site is one artifact for the whole repository): the workflow copies this
page to the site root, so its URL stays the one above, and runs on every push to `main` that
changes it. Only `privacy-policy.html` is copied — this README is not published.

One manual step, in the repository settings, done once:

**Settings → Pages → Source: GitHub Actions**, then run the *Pages* workflow from the Actions
tab. Until it has deployed, the switch leaves the site without the policy page. Before
2026-09-19 the source was *Deploy from a branch → `main` / `/docs`*.

Then load the URL in a private window to confirm it is public and needs no login — the
workflow's smoke test also fetches it after every deployment.

## What is *not* here

Project documentation lives elsewhere and is not published: `.llmwiki/` for durable
knowledge, `.claude/skills/` for procedures, `README.md` for newcomers. Anything added to
this directory becomes publicly served, so put nothing here that is not meant to be read by
anyone.
