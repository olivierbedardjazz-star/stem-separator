# Releasing Stem Separator

The app is free, native SwiftUI, Apple Silicon only, macOS 14+. One public repository holds reviewed source and release assets. Signing and notarization run on the owner's Mac. GitHub Actions builds and verifies independently with read-only permissions and no Apple/Sparkle secrets.

## Stable identity

Keep `com.oliviergrenierbedard.stemseparator`, team `5SVUWU2ZGY`, and the feed in `Packaging/release-config.json`. The local Sparkle Keychain account is `stem-separator-ed25519`. The trusted public key is in `project.yml`. Never generate or rotate keys during ordinary releases. Never put private keys or credentials into Git, logs, artifacts, or a public runner. A working local Keychain is not a separate backup; establish an owner-controlled secure backup separately when appropriate.

## Exact order

1. Finish code, notices and version/build in `project.yml`. Regenerate using pinned XcodeGen. Test Debug and Release as appropriate. Review `runtime/provenance.json`, artifact locks and corresponding-source obligations for every changed dependency. Check the public source allowlist with `scripts/audit_public_source.py`.
2. Commit reviewed source locally. Run `scripts/archive_release_app.sh`, then `scripts/export_release_app.sh`. The latter signs all nested runtime code, regenerates its manifest and seals the outer app, then runs the actual offline worker/control proofs.
3. Run `scripts/prepare_provisional_release_dmg.sh` and `build/StemRuntime/portable-venv/bin/python scripts/release_pipeline.py install-proof`. Drive the signed installed app's native workflow using the installed-path XCTest harness. Record `local-ui-proof.json`. Preserve the previous public app separately for updater testing.
4. Only after the complete local bundle works, push the exact source and wait for both `Clean macOS build` jobs. Save the run ID, SHA, conclusion and URL in `ci-proof.json`. The Apple submission command rechecks GitHub's live exact-source result.
5. Run `scripts/submit_notarization.sh`. It records one submission; repeat it to query status. An `In Progress` response means wait, not failure or acceptance. After `Accepted`, run `scripts/staple_exported_app.sh`.
6. Run `scripts/prepare_release_dmg.sh`, `scripts/notarize_release_dmg.sh`; query until Accepted. Run `build/StemRuntime/portable-venv/bin/python scripts/release_pipeline.py staple-dmg`.
7. Run `scripts/prepare_sparkle_release.sh`. The pinned generator signs the ZIP and appcast using the stable Keychain identity. A separate public-key verifier validates both; do not add a redundant private-key signing step. Assets also include matching corresponding sources and SHA-256 checksums.
8. Review immutable assets and run `scripts/publish_github_release.sh`. It uploads a complete draft before promotion, downloads each published asset anonymously, compares hashes, and verifies the stable latest feed. Do not rebuild or replace published bytes. If an upload is interrupted, inspect the draft and its hashes before resuming; the command intentionally refuses an existing release instead of overwriting it.
9. Dispatch `Verify published installer` with the immutable tag. Both hosted macOS versions download the DMG, check signatures/tickets, copy its app, add quarantine, perform Gatekeeper assessment, and run offline inference with empty HOME/minimal PATH/network denied. This is automated installed-binary proof, not a human Finder or fresh-account UI test.
10. Use the installed previous public app's Help → Check for Updates command to install and relaunch the new public version through Sparkle. Do not substitute manual copying. Check version, signatures, preferences and a new complete separation. Save `two-version-update.json` and `published-install-proof.json` with actual result/limits.
11. Run `build/StemRuntime/portable-venv/bin/python scripts/release_status.py release-evidence/<version>-<build> --complete`. Archive logs and sanitized evidence. Tag identity refers to the exact app source; later documentation-only commits do not change released binaries.

## Test harness

Build `UITests/StemSeparatorUITests.swift` with `xcodebuild build-for-testing`. Copy the generated xctestrun beside its original in the same Products directory so relative test paths remain valid. For a signed installed workflow, set the UI target's `UITargetAppPath` and `EnvironmentVariables.STEM_TEST_APP` to the exact installed app. Run only `testNativeWorkflowMenusAndLegalSurface`. `testInstalledAppReportsUpToDate` checks the current release. `STEM_TEST_PREPARE_UPDATE=1` optionally chooses Cosmic Composer from the initial Jazz Virtuoso theme for migration proof.

For actual updating, set `STEM_UPDATE_APP` to the installed predecessor and `STEM_UPDATE_BUILD` to the successor's build; run only `testInstalledSparkleUpdate`. This test drives Sparkle, observes Info.plist changing, and checks relaunch. Complete offline separation and preference/hash checks are separate evidence. Tests must run sequentially when sharing app identity. Never rebuild a bundle during its active job.

## Recovery and retention

Keep app archives, accepted app/DMG, ZIP, signed appcast, source archive, checksums, CI logs and submission IDs in ignored `release-evidence/<version>-<build>/`, outside disposable `build/`. Earlier stage fingerprints can differ after documented signing/stapling transformations; final fingerprints must still match. Never use old template timestamp stamps to authorize a release.

A failed published version is corrected forward with a higher version/build and repeated gates. Preserve immutable prior release assets. Do not assume transparent downgrade or key rotation works with signature-before-extraction enabled. Review pinned Sparkle's key-recovery requirements before any intentional key change.

Full evidence remains local in this workspace; no separate backup destination was configured. Private signing material stays in Keychain. Do not remove user audio, results, or unrelated applications while cleaning test artifacts. Copies under `release-evidence/UpdaterProof` and each version's `Installed Applications` are test-owned and explicitly identified.
