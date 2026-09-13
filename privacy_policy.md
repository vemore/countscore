# Privacy Policy for CountScore

**Last Updated**: September 13, 2026

**Effective Date**: Applies to CountScore v1.1.0 and later

**Previous versions**: v2.2 (September 11, 2026), v2.1 and v2.0 (September 9, 2026) and v1.0 (November 9, 2025). v1.0
applies to CountScore 1.0.x — the versions currently on the Play Store. See
[Version History](#version-history).

**Published at**: https://vemore.github.io/countscore/privacy-policy.html

## Introduction

This Privacy Policy describes how CountScore ("we", "our", or "the app") handles information
when you use our application. CountScore is developed by vemore and is available on the
Google Play Store.

**In short**: CountScore stores your games on your device and requires no account. It has no
analytics, no tracking and no advertising. Out of the box it sends nothing anywhere: the app
contains **no server address at all**. There are **two** optional features that can send data
off your device, and both require you to first enter, in Settings → Server, the address of a
backend **you** run:

- the **ZapZap analysis**, which runs only when you ask for one; and
- **group sharing**, which runs only after you also create or join a group, and only for the
  games you share with it.

Both are described in full below.

## Developer Information

- **Developer**: vemore
- **Contact Email**: scribio.ai@gmail.com
- **App Website**: https://github.com/vemore/countscore

For the purposes of the GDPR, vemore is the data controller for the processing described in
this policy.

## Information Stored on Your Device

CountScore stores the following **locally on your device**:

1. **Game Information** — game type names and settings (e.g. "Uno", "Scrabble", custom
   games), scoring rules (lowest-wins or highest-wins), colours and icons.
2. **Player Information** — player names you create, and their association with games.
3. **Score Data** — scores, round-by-round history, any comment you attach to a round,
   timestamps, and completed-game results.
4. **App Preferences** — theme, language and other interface settings.
5. **Cached analyses** — the text of any ZapZap analysis you have generated.
6. **Group membership**, if you create or join a group — the group's name, this device's
   identifier in the group, and a record of which changes have been sent. The two group
   secrets (this device's access token and the group's invite code) are kept in the
   platform's secure storage (the Android Keystore; encrypted browser storage on the web),
   not in the database.

### Storage technology

- **SQLite database** (via Drift) — game types, players, rounds, scores, cached analyses.
  On Android this is a local database file; in the web version it is a browser-local
  database (OPFS).
- **SharedPreferences** — app settings and preferences.
- **Local file storage** — for the optional database export/import feature (Android only).

This data is not backed up to us or uploaded anywhere, with one exception you choose game by
game: a game you **share with a group** is synchronised with your server and the group's other
devices, as described in [Group Sharing](#group-sharing). Everything else stays on your device
until you delete it.

## Feature One: ZapZap Analysis

CountScore includes an optional feature that generates a written analysis of a finished
ZapZap game using a large language model (LLM).

**It is switched off until you supply a server.** The app is published with no backend
address, and none is compiled into it. Until you enter one in **Settings → Server**, the
analysis is not offered anywhere in the interface and the app makes no network request
whatsoever. The server you enter is one you host yourself — the source for it is in the
`backend/` directory of the public repository. We operate no service on your behalf, and we
receive no data from you at any point.

Once a server is configured, **the feature still never runs automatically.** No data is sent
unless you open a game's analysis screen and explicitly tap the button to generate one.

### What is sent

When you request an analysis, the app sends the following for that game:

- the game's name, its game type, its scoring rule and its creation date;
- the **names of the players** in that game;
- every round: its number, its scores, and **any comment you typed on that round**;
- a **history for each player**, drawn from up to 10 of their other games (their past results
  under the same name).

Round comments are free text. Whatever you type there is included, so please do not put
anything sensitive in them.

Player names are chosen by you. If you enter a real full name, that name is transmitted. We
recommend first names or nicknames.

### Where it is sent

1. **To the backend whose address you entered** — normally a machine you own, running the
   CountScore server software from the `backend/` directory. The connection is encrypted
   (HTTPS/TLS); the app accepts an unencrypted `http://` address only for a private or
   loopback address such as `192.168.1.10` or `localhost`, so that a server on your own home
   network works without a certificate. That server software is **stateless** for this
   feature: it does not write your game data to any database, and keeps no copy of it after
   the request completes.
2. **From there to an LLM provider**, which generates the analysis text. Which one depends on
   how *your* server is configured: **Amazon Web Services (Bedrock), Google (Gemini), or
   Mistral AI**. Your data is processed by that provider under **their** terms and retention
   policy, which neither we nor this app control.

Because the destination is chosen by you, the operator of that server is responsible for it.
If you point the app at someone else's server, you are trusting that operator.

The generated text is returned to your device and cached locally, so an analysis is only
generated once per game.

### Your IP address

To prevent abuse of a paid API, the server software applies a rate limit (5 requests per
minute, 30 per hour). This inspects the requesting IP address in server memory only. It is
not written to a database and is discarded once the time window elapses. If a request to the
LLM provider fails, the server writes a technical error entry to its log to allow diagnosis.
Those logs are on the server you run, not on any machine of ours.

### Legal basis and how to avoid it entirely

The processing above is carried out **on the basis of your consent**, given twice: once by
configuring a server, and again by tapping the generate button. **If you never configure a
server, no data can leave your device at all** — and even with one configured, nothing is
sent until you ask. There is no way for it to be triggered by anything else in the app.
Clearing the server address in Settings switches the feature back off.

## Group Sharing

Group sharing lets several devices — a family's phones, say — keep the same games and scores
up to date with each other.

**It is off until you do three things.** You must (1) enter the address of a server you host
in **Settings → Server**; (2) create a group, or join one with an invite code someone gave
you, in **Settings → Group**; and (3) share a game. While you are in a group, new games are
shared by default — the switch is shown on the "New game" screen and you can turn it off —
and an existing local game is shared only if you choose "Share with the group" on it. Games
you do not share never leave your device.

### What is sent

For each **shared** game, and kept up to date as you play:

- the game's name, its game type (name, icon, colour and rules), its scoring rule and its
  creation date;
- the **names and colours of its players**;
- every round: its number, **any comment you typed on it**, and its scores;
- its ZapZap analysis, if one was generated.

When you create or join a group, the app also sends the **group name** and the **name you give
this device** (both typed by you). The server issues this device an identifier and a secret
access token; the token authenticates each later request.

Player names and round comments are chosen by you; please prefer first names or nicknames and
keep anything sensitive out of comments.

### Where it goes, and what is kept

1. **To the server whose address you entered**, over HTTPS (or `http://` only on a private
   or loopback address, as above), plus a WebSocket connection over the same channel that
   only tells the app when there is something new. **Unlike the analysis, the server stores
   this data**: the current state of each shared game, and a log of every change made to it,
   which is how devices catch up after being offline. The server also records, per device,
   its name, when it joined and when it was last seen.
2. **To the other devices in the group**, which download the shared games from that server.
   Anyone who has the group's invite code can join the group and see its shared games, so
   share the code only with people you mean to share with; you can replace it in Settings.

No LLM provider is involved in group sharing, and nothing is sent to us.

### Leaving, and deleting

- **Deleting a shared game** deletes it on every device in the group. On the server it is
  marked deleted, but its earlier content remains in the change log.
- **Leaving the group** (Settings → Group) revokes this device's access token — when the server
  can be reached at that moment; otherwise the token is only erased from the device — and
  turns your copies of the shared games back into local games. It does not remove the games from the
  server or from the other devices.
- **Removing the data from the server** is done by whoever operates it — normally you. The
  server software deletes a group and everything in it when its row is removed.

### Legal basis

Consent, given by configuring a server, joining a group and sharing a game — and withdrawn by
leaving the group or clearing the server address.

## Information We Do NOT Collect

CountScore does **not** collect, transmit, store, or share:

- ❌ Personal identification information — we have no accounts, and never ask for your name,
  email, phone number or address
- ❌ Device identifiers (IMEI, MAC address, Android ID, advertising ID)
- ❌ Location data
- ❌ Usage analytics or statistics
- ❌ Crash reports or diagnostic telemetry
- ❌ Any data from other apps on your device
- ❌ Photos, contacts, or other device data

We do not use any analytics SDK, advertising SDK, or tracking library of any kind.

## How Information Is Used

- **On your device**: to store and display your games, scores and preferences.
- **In the ZapZap analysis**: solely to generate the requested analysis text and return it to
  you.
- **In group sharing**: solely to keep the shared games identical on the group's devices.

**No data is used for analytics, advertising, profiling, or any other purpose, and nothing is
ever sold.**

## Data Sharing and Third Parties

Apart from the ZapZap analysis and group sharing described above, CountScore shares no data
with anyone — and both features require you to nominate the server yourself. Group sharing
also makes shared games visible to the other devices of the group you joined.

For it, the operator of the server you configured, and the LLM provider that server uses
(AWS, Google or Mistral AI), process the analysis request. Where you run the server, that
operator is you. We do not share data with analytics providers, advertisers, data brokers, or
social networks, and we do not sell data.

### International transfers

The LLM providers may process the request outside your country and outside the European
Economic Area. Where that occurs, it relies on the provider's own transfer safeguards
(such as Standard Contractual Clauses). If this matters to you, leave the server address
empty or choose an LLM provider and region yourself when configuring your server — the rest
of the app is unaffected either way.

## Data Security

1. **Local storage**: data on your device is protected by your device's own security
   (screen lock, disk encryption).
2. **Encryption in transit**: the analysis request and group sharing use HTTPS/TLS (and a
   WebSocket over TLS).
3. **Server-side storage**: the analysis endpoint retains nothing after answering. Group
   sharing stores shared games on the server you configured; the device access token is
   stored there only as an argon2 hash, and on your device only in secure storage.
4. **Minimal permissions**: see [Permissions](#permissions).
5. **Open source**: the code that performs the request can be inspected by anyone.

No method of transmission over the internet is completely secure, and we cannot guarantee
absolute security.

## Your Data Rights

### Access
All your data is visible in the app.

### Deletion

**Option 1 — Delete specific data**: delete individual games, rounds, players or custom game
types in the app. Deleting a game also deletes its cached analysis.

**Option 2 — Delete all app data**: Settings → Apps → CountScore → Storage → Clear Data.

**Option 3 — Uninstall**: removes all app data permanently.

Because we keep no copy of your data on any server, there is nothing for us to delete on our
side, and nothing to restore if you delete it locally. Games you shared with a group are also
held by the server you configured and by the group's other devices — see
[Leaving, and deleting](#leaving-and-deleting). For data held by an LLM provider from
an analysis request, contact that provider under their own privacy policy.

### Portability
Android builds offer a database export/import feature, giving you a copy of your data as a
file. Your data is not tied to any account or service.

### GDPR rights
Users in the EEA and the UK have rights of access, rectification, erasure, restriction,
portability and objection, and the right to withdraw consent at any time (by clearing the
server address, leaving the group, or not using the analysis feature), as well as the right to complain to a
supervisory authority. Since we hold no server-side copy of your data and cannot identify
you, most of these rights are exercised
directly on your device. To ask a question, use the contact details above.

## Permissions

**The released Android app declares exactly one permission: `INTERNET`.** It requests no
runtime permissions — the kind Android asks you to approve with a dialog — at all.

- **`INTERNET`** is declared in `android/app/src/main/AndroidManifest.xml`. It exists for the
  ZapZap analysis and for group sharing, and nothing else: the app sends no telemetry. It goes
  entirely unused until you configure a server. While you are in a group and the app is open,
  it keeps a connection to your server and synchronises shared games in the background of
  that session; it does not run when the app is closed. Android grants the permission at
  install time without asking you, because it is not a runtime permission — which is why the
  safeguards that matter are the ones described above: there is no address to send to unless
  you supply one, and no game is shared unless you join a group and share it.
- **Unencrypted connections** are allowed by the app's network security configuration
  (`android/app/src/main/res/xml/network_security_config.xml`) solely so that a server on your
  own local network can be reached without a TLS certificate. The app itself refuses to store
  an `http://` address that is not a private or loopback one, so traffic to a public host is
  always encrypted.
- **Keeping the screen awake** during a game uses a window flag, not the `WAKE_LOCK`
  permission — nothing is requested and no data is accessed.
- **Storage**: the export/import feature uses the system file picker, which does not require
  a storage permission.

## Children's Privacy

CountScore requires no personal information to use and is suitable for all ages.

Please note that the ZapZap analysis and group sharing transmit the player names entered in
the app. If
children use the app, we recommend using first names or nicknames rather than full names, or
simply not using the analysis feature.

We do not knowingly collect personal information from children. As we operate no accounts and
run no server that receives your data, we hold no such information.

## Data Retention

- **On your device**: until you delete it, clear app data, or uninstall.
- **On a server we run**: nothing, because we run none that your app talks to. On the server
  *you* configure, the analysis endpoint stores no game data; IP addresses used for rate
  limiting live in that process's memory only and are discarded when the window elapses.
  Shared games, their change log and the group's device list are kept there until the
  operator deletes them.
- **At the LLM provider**: governed by that provider's retention policy, which we do not
  control.

## Open Source

CountScore is open-source software licensed under the MIT License, so its privacy claims can
be independently verified. Every network request described in this policy is issued from
`lib/services/backend_client.dart` (plus the WebSocket in `lib/services/sync/sync_stream.dart`),
and the address they use comes from `lib/providers/backend_provider.dart`, which has no default
value. What group sharing sends is built in `lib/services/sync/sync_store.dart`.

**Source Code**: https://github.com/vemore/countscore

## California Privacy Rights (CCPA/CPRA)

CountScore does not sell personal information, and does not share it for cross-context
behavioural advertising. We do not collect personal information for commercial purposes, and
we maintain no profile about you.

## Changes to This Privacy Policy

We may update this policy to reflect changes in the app's functionality or in legal
requirements. Updates are posted on this page with a new "Last Updated" date, and significant
changes are announced through app updates on the Google Play Store.

### Version History

- **v2.3** (September 13, 2026): Documents **group sharing**, which the app now implements:
  what a shared game sends, that the server you configure stores it with a change history,
  that the group's other devices receive it, how leaving and deleting work, and where the
  device's access token is kept. Removes the "Features Not Yet Active" section, which said
  the app did not use sync. Updates the permissions, security, retention and consent sections
  accordingly.
- **v2.2** (September 11, 2026): The backend address became a setting with **no default**.
  Earlier versions compiled in the address of a server run by the developer, so a ZapZap
  analysis was sent there. The published app now contains no server address at all: the
  analysis feature is hidden until you enter one in Settings → Server, the server is one you
  host, and the developer neither operates a service for you nor receives your data. Also
  documents the network security configuration that lets a server on your own local network
  be reached over `http://`.
- **v2.1** (September 9, 2026): Corrects the permissions section. v2.0 stated that the
  released app requests no permissions and that `INTERNET` was present only in development
  builds. That was true of the source at the time and made the ZapZap analysis unusable in a
  release build; the permission is now declared in the main manifest, so the shipped app
  declares `INTERNET`, for that one feature.
- **v2.0** (September 9, 2026): Updated for CountScore 1.1.0. Documents the optional ZapZap
  analysis feature, which sends game data to the CountScore backend and on to an LLM
  provider. Corrects the previous version's statement that no data is ever transmitted, which
  was accurate for 1.0.x but would not be for 1.1.0. Also corrects the permissions section:
  the app does not request `WAKE_LOCK`.
- **v1.0** (November 9, 2025): Initial privacy policy for CountScore 1.0.0. Accurate for the
  1.0.x releases, which contained no networking code.

## Contact Us

**Email**: scribio.ai@gmail.com
**GitHub Issues**: https://github.com/vemore/countscore/issues (for technical questions)
**Response Time**: We aim to respond within 48-72 hours

## Consent

By using CountScore, you consent to this Privacy Policy. By tapping the button that generates
a ZapZap analysis, having configured a server of your own, you additionally consent to that
game's data being transmitted to that server as described above. By joining a group and
sharing a game, you consent to that game being stored on your server and sent to the group's
devices as described in [Group Sharing](#group-sharing).

If you do not agree with this Privacy Policy, please do not use CountScore.

---

## Summary (TL;DR)

✅ **No account, no analytics, no tracking, no ads**
✅ **Your games are stored on your device**
✅ **You control your data and can delete it anytime**
✅ **Open-source and auditable**
✅ **Free, with no hidden costs**
✅ **No server configured by default** — the app ships with no backend address, so out of
the box it makes no network request at all
⚠️ **Two exceptions, both needing a server you set up yourself**:
- tapping "generate analysis" sends that game's player names, scores and round comments to
  **your** server and on to the LLM provider it uses (AWS, Google or Mistral); the server
  stores none of it;
- joining a group and **sharing a game** stores that game — player names, scores, comments,
  analysis — on **your** server, with its change history, and sends it to the group's other
  devices.

Leaving the address empty means nothing ever leaves your device.

---

*This privacy policy applies to CountScore v1.1.0 and later. For versions 1.0.x, see v1.0 of
this document in the repository history.*
