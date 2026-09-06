# Slice 377 — Nested Developer ID signing and execution

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 370 rights cleared for distribution, 374, 376. Outcome: the exact candidate has valid signatures throughout and the signed helper actually runs with hardened runtime.

## Exact file work

Create `scripts/sign_stem_runtime.sh`, `scripts/verify_stem_runtime_signatures.sh`, `Tests/Release/test_signing_inventory.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/signed-runtime.md`. Change `scripts/archive_release_app.sh`, `scripts/export_release_app.sh`, `scripts/finalize_exported_app_for_notarization.sh`, `scripts/sign_bundled_runtime_executables.sh`, `scripts/verify_notarization_readiness.sh`, `scripts/verify_signed_app.sh`, `scripts/create_runtime_manifest.py`, and `scripts/release_record.py`. Create `Packaging/StemWorker.entitlements` only if demonstrated runtime requirements justify specific exceptions. No speculative broad entitlement file.

## Low-level signing order and artifact flow

1. Freeze the exact source SHA/version/locks/config that passed local and CI proof. Verify Developer ID Application identity/Team ID and local Keychain access. Build/archive/export into the release-owned staging directory with explicit Xcode settings. Any Xcode export re-signing occurs before the final explicit runtime pass; treat exported bytes as a new recorded stage.
2. Stage all runtime/model/legal metadata and finish any architecture pruning/install-name repair before signing. Audit actual Frameworks/Resources symlinks, native modules and framework metadata. Preserve complete frameworks; an incorrectly shaped Python framework must be repaired at its build input, not papered over with deep signing.
3. Construct an inside-out inventory from actual Mach-O and nested bundle containment, deduplicating symlink aliases. Sign leaf dylibs/extension modules, then contained framework executables/bundles, then helper executable and helper app. Use Developer ID/timestamps; executable hosts receive hardened runtime and only justified entitlements. Do not stamp app entitlements onto every dylib. Retain explicit Sparkle Autoupdate/XPC/Updater/framework handling, after their children.
4. Recreate `Contents/Resources/StemRuntimeMetadata/manifest.json` from the signed helper **after** its final signature, before signing the outer app. Otherwise embed-time hashes become stale when signatures change. Keep pre-sign provenance separate. This manifest does not hash itself or the outer signature and therefore has no circular dependency.
5. Sign the outer app last with Developer ID, secure timestamp and hardened runtime. Verify each code item, expected Team ID, timestamp and appropriate flags/entitlements, then strict/deep verification of the outer resource seal. Parse the runtime flag as a bit/presence, not the current exact string `flags=0x10000(runtime)`. Reject ad-hoc distribution signatures, `get-task-allow`, unreviewed exceptions or missing code.
6. Execute the exact signed helper and the native app workflow with network disabled for separation and no ambient runtime. Verify the signature again afterward, proving the helper didn't modify its bundle. No runtime pip/pycache/model download may write into the signed app. Measure any JIT/library-validation failure; grant only the smallest demonstrated exception to the affected host and repeat signing/testing. Never switch Release hardened runtime off to pass.
7. Separate pre-notarization structural verification from final Gatekeeper acceptance. Existing verify_signed_app.sh calls spctl too early; give verification explicit phases. A missing ticket before notarization is not disguised as a signed-runtime failure or a final install pass.

## UI and dependency impact

Same UI and real worker. No new framework required. All signed code must match the reviewed runtime inventory; signature changes affect file hashes but not licence disposition. Signing keys stay in Keychain; no P12 export, CI import or new repository secret.

## Tests and packaging evidence

Test nested order/inventory using safe fixture trees and mocked commands; reject unrecognized code, escaping link, altered post-sign resource, wrong Team ID, missing timestamp and debug entitlement. Live proof includes main app launch, complete four-stem processing, cancellation and exit of the exact signed helper. Store signed code inventory/CDHashes and outer digest externally; no evidence file is injected after sealing.

## Stop conditions

Any unsigned/unlisted nested code, malformed bundle/framework, signed runtime crash, dependency outside the bundle, wrong identity or unsupported entitlement. Repair build inputs and repeat affected local/CI proofs before another candidate; notarization is not used as the first runtime-structure test.
