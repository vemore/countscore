# privacy_policy.md says the app declares "exactly one permission"

- **Noted:** 2026-09-18 — while rewording the same sentence in `README.md` Privacy (docs/wiki-sync)
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`privacy_policy.md` (§ Permissions, "The released Android app declares exactly one
permission: `INTERNET`.") makes the claim `README.md` Privacy made until docs/wiki-sync: the
merged release manifest also carries
`com.vemore.countscore.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, a signature-level,
app-private permission that `androidx.core` injects. `PLAY_STORE_DATA_SAFETY.md` already
expects it ("Expect `android.permission.INTERNET` alongside the generated
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`"). The policy is published
(https://vemore.github.io/countscore/privacy-policy.html), so a reword also means
republishing it — which is why docs/wiki-sync, scoped to the README, left it alone.

**Fix:** reword the sentence as in `README.md` Privacy — `INTERNET` is the one permission the
app declares; the androidx one is signature-level, private to the app, grants access to
nothing — and republish the policy page.

**Acceptance:**
- `privacy_policy.md` no longer says "exactly one permission" without naming the androidx one.
- The published policy page matches the file.
