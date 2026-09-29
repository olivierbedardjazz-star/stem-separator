# Mac App Store handoff status — 2026-09-28

The direct GitHub Developer ID/Sparkle 0.1.2 release has not been replaced. The Store variant is in pull request [#1](https://github.com/olivierbedardjazz-star/stem-separator/pull/1) from `codex/app-store`; do not describe it as submitted or public.

## Proven locally

- The Store Release archive at `build/AppStoreRelease/0.1.2-102/StemSeparator.xcarchive` builds from the dedicated Xcode scheme.
- Its worker contains the source-built, pinned LLVM OpenMP 23.1.2 library targeting arm64/macOS 15.1; the archive binary SHA-256 matches `Contents/Resources/StemRuntimeMetadata/store-libomp-provenance.json`.
- The ad-hoc-signed Store Release app at `build/AppStoreRelease/0.1.2-102/signed-local/Stem Separator.app` passed `StemSeparatorUITests/testNativeWorkflowMenusAndLegalSurface` on macOS 26.3.1: picker import, four-stem output, karaoke output, Finder reveal, menus, and legal modal. Result: `build/AppStore/StoreReleaseArchiveProof.xcresult` (1 passed, 0 failed).
- The Store app and helper have App Sandbox entitlements; the helper has sandbox inheritance. Strict/deep signature verification passed. No Sparkle framework or update feed keys are in the Store bundle.
- The direct Release target built successfully and still embeds Sparkle and its release feed. The local `scripts/ci_store_proof.sh` also passed after the Store build was committed.
- The sandboxed job-temp root and recovery journal were empty after the UI proof. Generated UI-test WAVs and the temporary OpenMP crash diagnostic were removed afterward.

## Why the OpenMP replacement exists

The Torch 2.6 wheel's bundled `libomp.dylib` aborted when App Sandbox denied its shared-memory registration (`OMP Error #179, Can't open SHM2`). LLVM's [sandbox issue](https://github.com/llvm/llvm-project/issues/80165) describes the same mechanism. A newer LLVM OpenMP build passed the real sandboxed workflow. `scripts/build_store_libomp.sh` pins the source version/hash, builds for 15.1, and records provenance. The Store target alone substitutes this library; the direct target keeps its tested wheel runtime. The full LLVM OpenMP licence is bundled.

## External gates

1. The explicit App ID `com.oliviergrenierbedard.stemseparator` was registered under team `5SVUWU2ZGY` in Apple Developer. Creating the App Store Connect record with macOS, name `Stem Separator`, English (U.S.), SKU `stem-separator-macos`, and full access was attempted, but the Apps page still showed **No Apps** afterward. The page states that the Account Holder must review and accept an updated Apple Developer Program License Agreement before new app submissions. The agent must not accept that agreement for the owner. After acceptance, verify whether the record exists before attempting to create it again.
2. This Mac's Keychain currently shows only the Developer ID Application identity. No Apple Distribution app identity, Mac Installer Distribution identity, or Store provisioning profile was found. `scripts/app_store_release.py sign`, `export`, `validate`, and `upload` remain unproven and must not be claimed complete.
3. App Store Connect has an existing Developer-role API key, but no Store submission credential was configured for this pipeline. Developer role may not permit App Review submission. Keep all `.p8` material outside the repository and owner-only readable.
4. The Store listing still needs real accepted-dimension screenshots, pricing/availability, privacy declarations, age rating, review contact/notes, a processed build, and review submission. Privacy and support pages are prepared in this branch; use their stable public GitHub URLs only after merge.
5. Clean GitHub Actions checks for PR #1 were pending when this status was written. Verify both macOS 15 and macOS 26 jobs before merge. Do not change the published direct-release assets as part of Store qualification.

## Resume order

Check PR #1 CI and resolve failures. After Account Holder agreement acceptance, check App Store Connect for an existing record; create only if absent. Obtain Store signing identities/profile through Apple-supported account/Xcode tooling. Run `scripts/app_store_release.py sign`, `verify-signed`, `export`, `validate`, then upload the tested package. Complete listing and submit. Poll Apple processing no longer than 15 minutes in one active turn; preserve build/submission IDs and resume later if it remains pending.
