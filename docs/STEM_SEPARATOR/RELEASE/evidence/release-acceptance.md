# Release acceptance — Stem Separator 0.1.1

Completed 2026-09-06. The recommended public release is **0.1.1, build 101**. Native SwiftUI, Apple Silicon, macOS 14+, free, one-file/four-stem workflow, Python/Demucs/model bundled. No end-user Python, Homebrew, ffmpeg or model download is needed.

[Download the installer](https://github.com/olivierbedardjazz-star/stem-separator/releases/download/v0.1.1/Stem-Separator-0.1.1-101-arm64.dmg) · [Release](https://github.com/olivierbedardjazz-star/stem-separator/releases/tag/v0.1.1) · [Maintenance instructions](../RELEASING.md)

## Immutable source and independent proof

| Version/build | App source commit | Clean build | Public installed binary |
| --- | --- | --- | --- |
| 0.1.0-100 | `1d5b902b8d5b94dede026be004b0a1642a1995c3` | [build proof](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/34058716469) | [downloaded installer proof](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/34061634309) |
| 0.1.1-101 | `8a0c90bdc9c06ac1646c4169b6bf58cc67f6615a` | [build proof](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/34060873522) | [downloaded installer proof](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/34061830508) |

The complete signed local bundle and native installation workflow passed before each release source was pushed for hosted builds. The hosted matrices passed on macOS 14/Xcode 16.2 and macOS 26/Xcode 26.3. The final candidate passed 12 release-tool tests and 15 native Debug tests on each clean builder.

## Apple and updater result

- APP notarization: **Accepted**, submission `64473f45-337d-46d3-8584-d62cb9aa8436`; ticket stapled and validated.
- DMG notarization: **Accepted**, submission `c3bd8d75-7c73-4ce7-ba5f-afb11dfab965`; ticket stapled and validated.
- Every public asset was downloaded anonymously and matched its local hash; the stable latest feed matched the signed appcast.
- Real installed 0.1.0 → 0.1.1 Sparkle download/install/relaunch passed. The updated app fingerprint exactly matched the notarized successor, with valid signature/ticket. No manual successor copy was substituted for this transition.
- Theme, responsible-use acceptance, output-folder bookmark hash, original fixture and previous synthetic outputs survived. The updated app completed offline helper inference and the full native picker/separation workflow; Help → Check for Updates correctly reported current afterward.

## Final assets

| Asset | Bytes | SHA-256 |
| --- | ---: | --- |
| Corresponding-Sources.tar.gz | 143855813 | `b3858ea53965555a70e4eec186884a5227c83113f6598662f272031c254a69e4` |
| SHA256SUMS.txt | 375 | `e6aeb190333f4fa85a1803dae65cb3ee92ee1dd97484680076feb2c4e3eaad74` |
| Stem-Separator-0.1.1-101-arm64.dmg | 198870572 | `7a430cd29615d8fde7f6441bc2a50dd39acf60523997be549a43f9e59f8e9609` |
| Stem-Separator-0.1.1-101-arm64.zip | 190637245 | `68fd70ddde525ef4fca998627ab1dddad13b1793bf033d9cd840718ca4b2f768` |
| appcast.xml | 1310 | `a9051a7128506c0a05952143d557d834a7d35d9626413770c19cd27be56782b8` |

The first-install DMG is approximately 190 MiB; the installed app occupies approximately 408 MiB on this filesystem. The separate corresponding-source archive is for licence compliance, not an end-user runtime installation step.

A final three-minute synthetic offline run completed 31 model chunks in **79.61 seconds** on the M1 Max. `time -l` reported maximum RSS of 2,582,757,376 bytes for the command/descendants. Cancellation and parent EOF after one completed chunk both exited 130 in about 0.04 seconds with no output directory.

## What was exercised

- Owner's Mac: Apple M1 Max, 64 GiB, macOS 26.3.1; Xcode 26.3. Earlier local Debug and optimized Release app-hosted suites each passed 15 tests. The corrected candidate passed signed offline helper/control proofs and the full native installed UI workflow before its source was pushed.
- The native suite covers WAV conversion/resampling, MP3/M4A/AIFF intake, stereo 24-bit/44.1 kHz output and frame counts, collisions, corrupt stem rejection, cancellation, missing worker/destination, sanitized error phase, workspace recovery, settings isolation, multiple-input rejection, clearing a pending selection without deleting source, destination-picker cancellation and updater configuration/busy state.
- UI automation selected audio, cancelled and reopened the native destination picker, separated with the bundled model, reached Finder-reveal readiness, opened Terms, and checked absence of Window/View menus. Synthetic files only; no user music was published. The X clears a reference; source hashes remained unchanged.
- Python runtime was reconstructed from pinned, hash-verified artifacts, with `pip check`, full dependency notices and an audit of 35 nested native binaries. All runtime-native dependencies resolve internally or to macOS system libraries; the unused unbundled SoX extensions were removed. The four-stem checkpoint remains exactly the owner-assessed historical MIT checkpoint.
- Actual frozen inference runs with empty HOME, minimal PATH and network denied. Four finite stereo outputs and real completed chunk counts were verified. Cancellation and parent EOF exit promptly; invalid requests fail; altered model bytes are rejected before model loading.
- Final signing seals native leaves and nested containers, regenerates the worker manifest after signing, and signs the outer app last. App and DMG each require Apple Accepted, then stapling and validation. Gatekeeper reports Notarized Developer ID.
- Signed appcast and ZIP are verified using the public key embedded in the app. Altered same-length feed, altered same-length ZIP, unsigned feed and wrong key were rejected by the release verifier. These are verifier tests, not a claim of full end-to-end malicious-feed testing of every Sparkle attack scenario.

## Scope, deviations and retained limitations

The release specifications are planning records. Actual implementation consolidates the release phases in `scripts/release_pipeline.py` and per-stage fingerprinted JSON records, with existing shell entry points. Several proposed one-purpose scripts/test files were replaced by this shared implementation, the native UI harness, and the public installer workflow. No placeholder pass files substitute for commands or observed results.

Local installation proof mounted each DMG read-only and copied its app into a clearly named installation directory inside this workspace, then drove the signed app with XCTest. It did not perform a human Finder drag into `/Applications`, a browser download prompt, a fresh local account, or a second physical Mac GUI session. Hosted tests exercised clean macOS 14 and 26 environments, including actual offline runtime execution; the downloaded-installer workflow additionally applied quarantine and ran Gatekeeper assessment. This is useful machine-independent evidence with a narrower scope than a second person's interactive install.

A later repeated local Debug test launch stalled inside dyld before app startup. Samples and logs were retained, test processes stopped, and no privacy database was edited and no Gatekeeper rule or Keychain ACL was relaxed. Earlier local Debug tests passed; the latest native source is independently retested by the exact-source hosted Debug suites, while the actual signed local production bundle is exercised through the full UI. Test-only ad-hoc/hardened-runtime overrides never enter production signing.

No minimum-RAM or all-device performance claim is inferred from the M1 Max benchmark. No physical low-memory machine, full 20-minute musical track, external-volume/iCloud matrix, or every interruption point was exhaustively tested. Synthetic three-minute inference gives an observed performance sample, not an audio-quality rating or performance guarantee.

All original theme, typography, primary-button halo/press/bloom and footer/social primitives were reused. Protected source hashes matched the baseline. Existing banner/social destinations were retained by explicit owner decision. Model redistribution follows the owner's documented assessment; it is not represented as an independent legal opinion. Licence texts and relevant corresponding sources are included with attribution/relinking guidance.

Free pricing replaces paid licensing/accounts. Private source plus separate updates repositories and GitHub signing secrets are not applicable: the owner explicitly chose one public source/releases repository and local signing. Source/artwork ownership remains described by the root LICENSE; public visibility was not silently turned into an MIT grant for the entire app.

Exact final artifacts, submission IDs and logs are retained locally under `release-evidence`, outside `build/`; public Releases preserve immutable distributables and source tags. There is no separately configured backup destination for this workspace or private keys. Private signing material remains in local Keychain. Keeping a secure owner-controlled backup and obtaining broader physical-device/user testing are follow-up maintenance tasks, not claimed completed here.

During the updater UI test, XCTest handled an interrupting system permission dialog using its default “Don’t Allow” action. The upgrade, relaunch, settings checks and post-update workflow still passed. No OS permission bypass was used.
