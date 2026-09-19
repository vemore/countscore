# Documentation

> Scope: which documents a change implicates — the wiki (conventions in `INDEX.md`),
> `README.md`, the three privacy documents — and the `CLAUDE.md` budget. No hook enforces
> these: they need judgement ([[Hooks]]).
> Related: [[Hooks]] · [[Release]] · [[Security]] · [[ParallelDelivery]]
> Updated: 2026-09-19

## Facts

### `README.md`

It makes claims about the code, and it is the only document a newcomer reads *before*
running anything. A change touching one of these implicates it, in the same change:

| What you changed | What to check in `README.md` |
|---|---|
| Flutter/Dart version, or `environment:` in `pubspec.yaml` | Version badge · Prerequisites · Tech stack |
| A dependency added, removed, or bumped a major | Tech stack |
| **A step needed to build a fresh clone** | Getting started — a missing step here means a clone does not compile; treat it as a defect, not a doc nit |
| A build flag, or a new build target | Building for production |
| A new top-level directory, or a new `lib/` subdirectory | Project structure |
| A CI job | Continuous integration |
| Platform support gained or dropped | Platform badge · Getting started · Building |
| Anything that sends data off the device | Privacy — and the rule below |
| A feature a user would notice | Features |

Verify against the source, never against the old README: versions come from `pubspec.yaml`
and the toolchain table in [[MobileApp]], not from the line already written. If the change
falsifies nothing in that list, the README needs no edit — say so and move on rather than
touching it for its own sake.

### A new outbound data flow — three documents and a permission

`README.md` (Privacy), `privacy_policy.md` and `PLAY_STORE_DATA_SAFETY.md` each describe what
leaves the device. Adding a network call, a new recipient, or a new field to an existing
payload means updating all three in the same change — and checking that
`android/app/src/main/AndroidManifest.xml` grants the permission the flow needs, since
`INTERNET` lives only in the debug and profile manifests by default. A Play Store data
safety declaration that does not match the binary is a policy violation, not a stale line.
The flows as they stand: [[Security]].

A user-initiated hand-off to another app — the system share sheet (`share_plus`, since
2026-09-19), a `mailto:` in the user's own mail app — is **not** such a flow: the app sends
nothing and receives nothing, and the user picks the recipient. It moves no Data Safety
answer; `PLAY_STORE_DATA_SAFETY.md` records each one in a dated note saying so, and the
merged release manifest must still gain no permission from it.

One part of this is mechanical: CI fails a pull request whose `docs/privacy-policy.html` is
stale against `privacy_policy.md`, or whose policy changed without its `**Last Updated**` line
changing (`scripts/build_privacy_page.py --check`, [[Testing]]). Whether the three documents
agree with each other and with the code is still judgement.

### The `CLAUDE.md` budget

At most **120 lines**. It keeps only what every session needs before reading anything else:
what the project is, the no-default-backend rule, "read the wiki first", the non-negotiables,
and each workflow rule as one short statement with a pointer. Anything past the budget moves
to the page that owns it. The rules themselves are pruned before each release
(`release-android` §3b, [[Release]]).

## Decisions & History

- **The README table (2026-09-09).** `README.md` drifted for ten months because no rule said
  when a change implicated it. The table names the triggers instead of asking for judgement
  on every change.
- **The three privacy documents (2026-09-09).** The audit behind the rule is in
  `wip/done/ARCHIVE-2026-09.md` (2026-09-09): the analysis shipped while the data safety
  declaration said nothing left the device, and the release manifest lacked `INTERNET`.
- **A size budget for `CLAUDE.md` (2026-09-14).** Between 2026-09-09 and 2026-09-14 about
  40 % of the lines written were process rather than product, and every incident had become a
  rule while none had been removed (`wip/done/2026-09-14-process-only-grows.md`). The user
  capped `CLAUDE.md` at 120 lines (it was 204): details moved to the page that owns them —
  this page took the README table and the privacy rule. The periodic pruning pass decided the
  same day is recorded in [[Release]].
