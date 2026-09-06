# Slice 383 — Evidence, handoff and repeatable maintenance

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 382. Outcome: a release can be audited and repeated without rediscovering local state or losing update continuity.

## Exact file work

Create `docs/STEM_SEPARATOR/RELEASE/evidence/release-acceptance.md`, `docs/STEM_SEPARATOR/RELEASE/RELEASING.md`, `scripts/release_status.py`, and `Tests/Release/test_release_status.py`. Change `docs/000_CHECKLIST_APP.md`, `docs/PACKAGING/README.md`, `docs/PACKAGING/354_packaging_release_order_and_failure_prevention.md`, `scripts/RELEASE_PIPELINE.md`, `docs/README_ARCHITECTURE.md`, `docs/STEM_SEPARATOR/000_IMPLEMENTATION_INDEX.md`, `docs/STEM_SEPARATOR/004_ACCEPTANCE_MATRIX.md`, `README.md`, and `.gitignore` as needed to make the actual proven lane the current documentation. Historical 355–366 files stay marked historical rather than falsely checked complete.

## Low-level handoff

Aggregate evidence by explicit source SHA/version: cold CI run, native local tests, dependency/rights inventory, signed-runtime/code inventory, provisional DMG install, accepted app/DMG submissions and logs, ticket validation, final artifact hashes/public URLs, normal downloaded install, and A→B result. `release_status.py` reads records and reports missing gates; it never manufactures pass states or publishes.

Preserve final app/export, DMG, updater ZIP, signed appcast/notes, checksums, source/lock identity and submission records under ignored `release-evidence/<version>-<build>/` outside disposable build/. Publish only sanitized summaries. Verify files can be re-read and hashes match. Back up to an existing owner-controlled secure backup if available; if none is available, record local-only retention honestly. Keep Keychain credentials in Keychain. Document key account/fingerprint and recovery procedure; never write raw key exports into this workspace or invent a backup destination/password. A separate backup of private key material, if later chosen, must use secure owner-controlled storage.

Write a concrete command sequence using the implemented scripts/config, including preflight/status, cold proof, archive/export, signing/verification, provisional installation, notarization submit/resume/log, app staple, final packaging, DMG acceptance/staple, feed generation, publication and final installed checks. Commands use explicit version/source/artifact inputs and can resume at a verified stage. Include actual notary status and GitHub run watch commands when a run exists, not fake IDs.

Future updates increment build/version, preserve stable bundle ID/feed/key, validate changed code/dependencies and repeat release gates. Never reuse a released version URL for changed bytes. Record how to pause promotion/keep prior latest when upload fails and how to recover forward with a higher known-good build if a bad release escapes. Do not promise transparent downgrade or arbitrary key rotation: this app's verify-before-extraction policy affects supported key-recovery routes and must be checked against pinned Sparkle documentation at that time.

Keep installed app copies clearly identified. Stop old test instances without interrupting user work and remove only confirmed task-owned disposable artifacts. Never recursively delete all copies named Stem Separator or sweep another product's release folder. User audio/results are not cleanup targets.

## UI/dependencies/licences

No feature or dependency changes after acceptance. README explains free/native/offline scope, hardware/OS limits backed by measurements, support and DMG installation. Do not announce macOS 14 or clean second-Mac proof without recorded evidence. Update legal/third-party notices for any future changed runtime before signing again.

## Tests / completion

Test missing/tampered evidence and incomplete update proof produce an incomplete status. Every shipping checklist item gets an evidence reference or an explicit justified not-applicable entry: two private/public repos and Actions signing secrets are replaced by the owner-approved single-public/local-signing design, not silently omitted. Physical-device/account coverage is stated precisely. Report remaining limitations, not a blanket production-ready claim.

## Stop conditions

Missing final artifact, unverifiable source/CI identity, unarchived submission result, no working updater transition, lost key access or falsely completed checklist. A release is complete only when the actual downloaded app and update work and their evidence is retained.
