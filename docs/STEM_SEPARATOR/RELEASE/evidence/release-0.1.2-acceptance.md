# Release acceptance — Stem Separator 0.1.2 / 102

Completed September 15, 2026 (America/Toronto; September 16 UTC). Free, native SwiftUI, Apple Silicon, macOS 15.1+, bundled offline HTDemucs/Python, MPS inference with required internal chunking. Adds Create Karaoke beside Separate Stems. Karaoke writes only one accompaniment WAV; it never serializes a vocal or individual accompaniment stem.

[Release and installer](https://github.com/olivierbedardjazz-star/stem-separator/releases/tag/v0.1.2) · [Plan and six slices](../../KARAOKE/002_RELEASE_SLICES.md)

## Immutable source and proof

- App source/tag: `1f0bdbdc451dcc955fd4c9b8a5f47b24b10a713a`, `v0.1.2`.
- [Clean macOS 15 and 26 builds](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/35045616824): both successful; 20 native tests on each, actual offline MPS inference in both output modes (no GPU skips), 16 release/tool tests and native runtime audit.
- Local: 20 native tests, 16 release/tool tests; 100-workspace/fault-injection recovery, temporary-root purge, permissions/retry, owner/symlink/bookmark protection, separate-volume capacity and actual unmount/remount passed. Signed provisional-DMG installation and both native workflows passed before source push.
- [Published installer verification](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/35047158873): both OS versions downloaded the public DMG, validated checksums, nested signatures and tickets, applied quarantine, passed Gatekeeper and ran actual offline MPS stems/karaoke.
- First published-installer run hit a shared-runner anonymous metadata API rate limit before downloading. Verification-only commit `61a109553dc9ac930ec9404243ba9b87d01f45aa` uses the ephemeral read-only Actions token for metadata; assets remain anonymous. No app or release bytes changed. It also cleans unit-test-only journal fixtures; three targeted tests passed.

## Apple and updater

- App Accepted: `c67c24a1-2e8b-462a-8c2c-20c30205d225`. DMG Accepted: `79cae966-6bbb-42d0-b11b-9bb86ee91929`. Both stapled and validated; app Gatekeeper accepted as Notarized Developer ID.
- ZIP and feed Ed25519 signatures, URL, length, version and minimum macOS15.1 verified with the bundled public key. Every public asset and stable latest feed downloaded anonymously and matched local bytes.
- Real Sparkle 0.1.1/101 → 0.1.2/102 download/install/relaunch passed using a fresh predecessor copy. No manual successor copy substituted. Updated app fingerprint exactly matches the notarized app; signature/ticket/Gatekeeper passed.
- Theme, responsible-use acceptance, output bookmark and existing fixture/output hashes survived. Updated app then passed native stems and karaoke workflows and Help → Check for Updates reported current.
- Fingerprints of both previous release directories and the original `STEM_SEPARATOR-RELEASE` handoff remained unchanged.

## Duration and storage qualification

Deterministic non-silent synthetic stereo fixtures; not a real-song listening corpus. Measured on the owner's 64 GiB Mac, alongside other machine activity; sampled process RSS excludes some GPU-driver allocations and is not a minimum-RAM guarantee.

| Duration | Mode | End-to-end | Peak sampled process-tree RSS | Remaining jobs |
| --- | --- | --- | --- | --- |
| 10 minutes | stems | 96.0 s | 4.40 GiB | 0 |
| 10 minutes | karaoke | 63.0 s | 4.39 GiB | 0 |
| 20 minutes | stems | 178.1 s | 7.76 GiB | 0 |
| 20 minutes | karaoke | 123.1 s | 7.77 GiB | 0 |

Six additional cancellation runs (inference, worker writing, native writing, both modes) passed without final outputs or leftover jobs. Installed Developer ID-signed engine additionally passed 20-minute karaoke in 122.9 s. Generated audio was removed after verification; metrics remain in release evidence.

Cleanup metadata now lives durably under Application Support/CleanupRecovery; no audio is stored there. Working audio remains temporary. Failed cleanup is visible and retried on launch, disk mount and the next job. Offline/read-only volumes cannot be erased until accessible; OS swap/backups are outside this cleanup contract. Final temporary job and journal inventories are empty.

Remaining coverage: subjective listening with real vocal music, 8/16 GiB hardware qualification, broader iCloud behavior and human fresh-account/Finder-drag workflows. Synthetic tests establish duration/format/storage behavior, not perfect vocal removal or all-device performance.

## Assets

| Asset | Bytes | SHA-256 |
| --- | ---: | --- |
| Corresponding-Sources.tar.gz | 143855813 | `735d169d0f80341969e1341c466dd01ba7f076ecbae12fcdafddac648147c023` |
| SHA256SUMS.txt | 375 | `76459bf71f0a509cdee50ee2dbf8d710ee3c3bee227d59fc403cfb827bb09652` |
| Stem-Separator-0.1.2-102-arm64.dmg | 202651055 | `804ae30234ddd01e94dc67683808d5f6af255ed4275e3de85ea84d0e3718d3e6` |
| Stem-Separator-0.1.2-102-arm64.zip | 193855067 | `1aaa2f06a3e94ffe302f83bd8edbbbdebc3f17372c390f610089ef4b6b11983a` |
| appcast.xml | 1310 | `c536bd2acda676a673191dc7cc5555fdd769ebb2c9cf3957ed8563cd5bebb011` |

Local artifacts/evidence: `release-evidence/0.1.2-102/`. Machine-readable final check: `scripts/release_status.py release-evidence/0.1.2-102 --complete`. Existing older handoff remains the 0.1.1 generation by design.
