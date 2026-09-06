# Slice 379 — App notarization and ticket stapling

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 378 and all frozen-candidate gates. Outcome: Apple explicitly accepts the submitted app and a ticket is attached to that exact candidate.

## Exact file work

Change `scripts/submit_notarization.sh`, `scripts/staple_exported_app.sh`, `scripts/verify_notarization_readiness.sh`, `scripts/release_record.py`. Create `scripts/check_notarization_status.sh`, `Tests/Release/test_notarization_state.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/app-notarization.md`.

## Low-level flow

Read the release record and independently verify source SHA/CI evidence, signed-app identity, signature inventory, provisional-install proof and input digests. Reject a changed app or a candidate built from a newer unproven checkout. The signed export tested in 378 is the submission source; do not silently rebuild after its installation test.

Use the existing local `notary-profile` through `notarytool`. Verify credential access without printing secret material. Build one submission ZIP with symlink-preserving ditto, containing the exact signed app. Record its hash/size before upload. ZIP is a submission transport, not the final Sparkle archive.

Submit and save structured output/submission ID immediately. Prefer a submit→bounded status-check→log flow so interruption is resumable. If the submission response is uncertain, consult recorded history/status before resubmitting the same payload; do not issue duplicate requests by reflex. Treat In Progress, Invalid, authentication/network errors and Accepted distinctly. A zero exit code or existence of a stamp is not sufficient evidence of Accepted.

Fetch and retain Apple's log for Accepted and Invalid outcomes; inspect warnings too. Mark accepted only when the submission ID maps to the recorded ZIP/candidate and explicit status is Accepted. On Invalid, identify the exact component from the log, repair its build input and create a fresh candidate with all affected checks repeated. Do not patch a submitted bundle in place.

Staple the accepted app, run stapler validate, then verify code signatures again and perform final-phase system assessment where supported. Ticket attachment is the sole permitted post-submission mutation; record before/after bundle digests and unchanged code identity. Do not write handoff records inside the app. `staple_exported_app.sh` must independently require the accepted record, not merely a path that stapler accepts from an unrelated earlier submission.

## UI, dependencies and licences

No UI/runtime/legal changes are allowed at this stage. Notarization is Apple's automated distribution check, not App Store review and not a model-licence decision. Local credentials stay in Keychain. Network access is needed for submission/timestamps/ticket retrieval; offline separation is a separate claim.

## Tests and packaging evidence

Mock structured responses for Accepted, Invalid, in-progress, malformed output, transport interruption and mismatched artifact/submission ID. Assert only Accepted enables stapling; tampering invalidates readiness. Live evidence includes exact signed source identity, submission ZIP hash, submission ID/status/log, ticket validation and post-staple signatures. Retain records outside build/.

## Stop conditions

Anything except explicit Accepted, missing logs, mismatched bytes, invalid signature, failed ticket validation or unresolved notarization warning. Never label a submitted or queued app notarized. No modifications except ticket attachment without restarting candidate proof.
