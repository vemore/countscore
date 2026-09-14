# Play Console upload is a browser step, not a script

- **Noted:** 2026-09-13 — tooling; `release-android` stops at a staged hand-off folder
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

A person or a browser agent must drive the Console to upload the bundle and paste the notes.

**Proposal:** the Play Developer Publishing API for the mechanical part only — upload the AAB
to a track as a **draft** with the notes. Gradle Play Publisher (`com.github.triplet.play`)
fits the Gradle build; fastlane `supply` is the alternative. Needs a service account with
release permission on this app only, its JSON key outside the repo plus a `.gitignore`
pattern, and a hook rule refusing to stage it. The browser brief then shrinks to the policy
survey, Data Safety, Content rating and sending for review.
