# `verify_aab.sh` fails in a French locale: `keytool` prints `SHA 256:`

- **Noted:** 2026-11-19 — building the 1.7.0 bundle on a `fr_FR.UTF-8` machine
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no — `LC_ALL=C JAVA_TOOL_OPTIONS=-Duser.language=en` makes it pass, but a release run hits it first

`.claude/skills/release-android/scripts/verify_aab.sh:31` and `:40` read the certificate
fingerprint with `sed -n 's/^[[:space:]]*SHA256: //p'`. With a French `keytool`,
`-printcert -jarfile` prints `SHA 256:` (a space), so the first check fails with "no SHA-256
fingerprint in the bundle certificate" on a bundle that is correctly signed. `play_publish.py
publish` re-runs the script, so it fails there too.

**Fix:** run both `keytool` calls under `LC_ALL=C` and `JAVA_TOOL_OPTIONS=-Duser.language=en
-Duser.country=US`, and accept `SHA[ ]?256:` in the pattern. Add a case to the script's tests
with the French output.

**Acceptance:**
- `verify_aab.sh` passes on a signed bundle with `LANG=fr_FR.UTF-8` and no other override.
- The test suite of `scripts/` has a fixture with the `SHA 256:` spelling.
