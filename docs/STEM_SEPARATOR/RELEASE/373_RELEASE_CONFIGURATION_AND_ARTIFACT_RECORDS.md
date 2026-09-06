# Slice 373 — Release configuration and artifact handoffs

Status: pending. Depends on: 371–372. Outcome: every release command acts on explicitly identified inputs and refuses stale or mismatched artifacts.

## Exact file work

Create `Packaging/release-config.json`, `Packaging/release-record.schema.json`, `scripts/release_configuration.sh`, `scripts/release_record.py`, `Tests/Release/test_release_record.py`, `Tests/Release/test_release_preflight.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/release-tooling.md`. Change `scripts/release_preflight.sh`, `scripts/build_local_release_app.sh`, `scripts/archive_release_app.sh`, `scripts/export_release_app.sh`, `scripts/finalize_exported_app_for_notarization.sh`, `scripts/submit_notarization.sh`, `scripts/staple_exported_app.sh`, `scripts/prepare_release_dmg.sh`, `scripts/prepare_provisional_release_dmg.sh`, `scripts/notarize_release_dmg.sh`, `scripts/prepare_sparkle_release.sh`, and `scripts/publish_github_release.sh` to consume shared configuration. Later slices implement their phase-specific behavior; this slice establishes/test-drives the contract.

## Low-level contract

Configuration contains product name, app/helper IDs, scheme/project, architecture/minimum OS, source/release repository (same value), feed, artifact stem and local Keychain account/profile names. Public IDs are configuration, not secrets. Version/build remain in project.yml and are read/compared with built Info.plist; avoid two independently editable version authorities. Secret values are never accepted in a committed JSON config.

Release record schema v1 contains release ID, version/build/tag, source commit and clean-tree status, configured-input digest, lock/model hashes, selected Xcode/SDK/tool versions, clean-CI run SHA/URL/result, relative artifact paths/size/SHA-256, pre/post-sign code inventory, app signing CDHash/Team ID, phase state, evidence references, notarization submission ID/status/log digest, and pre/post-staple artifact identities. Track full local artifact records under ignored `release-evidence/<version>-<build>/`; publish only a sanitized subset. Do not store bookmarks, tokens or signing private keys.

Commands implement guarded transitions: `inputs-verified → local-proven → ci-proven → signed → provisional-installed → app-accepted → app-stapled → assets-prepared → dmg-accepted-and-stapled → published → installed → update-proven`. These are evidence states, not flags that a caller can set to skip checks. The provisional DMG and final DMG have separate paths and hashes. JSON is parsed as data, never sourced as executable shell.

Every command requires the appropriate predecessor artifacts and independently checks their identity/hash. Old timestamp/path-only `.stamp` files cannot authorize a transition. Restrict output/deletion to the current release's owned directory; reject root/empty paths, path traversal and unexpected symlinks. Use argument arrays and structured/plist generation for paths with spaces/apostrophes. Hold a release-directory lock to prevent two jobs mutating the same candidate.

Archive/export preserves source/lock identity. `xcodegen generate` must agree with the committed generated project; dirty regeneration fails the release candidate rather than signing a new unseen tree. Record explicit `DEVELOPER_DIR`. No “newest” ZIP, DMG, Sparkle tool or app search. No publish-time prepare/build action. Same-repository local publication uses authenticated gh; remove template-specific token exceptions and UPDATES_REPO_TOKEN requirements.

## UI/dependencies

No UI changes and no new app dependencies. Build-only JSON helpers use the declared build Python. Keep release errors in developer tools; don't expose script state machines in product screens.

## Tests and packaging impact

Use temporary synthetic artifacts for missing stage, stale stamp, changed app/hash/version/repo, dirty tree, traversal, whitespace/Unicode, duplicate invocation and interrupted-record-write tests. Record writes are atomic. Verify a mocked Apple non-Accepted result cannot mark accepted. Tests never submit to Apple or upload to GitHub. Signing/stapling change bytes: tests must permit only the documented transition, regenerate hashes, and reject unrelated content edits.

## Stop conditions

Any identity mismatch, uncontrolled output selection, unverified predecessor, ambiguous repository, dirty candidate, or unsigned/provisional asset selected for publication. Complete when each entry point has the same explicit config/record boundary, even while later live proofs remain pending.
