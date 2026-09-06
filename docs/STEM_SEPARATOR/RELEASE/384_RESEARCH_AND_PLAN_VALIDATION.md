# Research and planning verification

Prepared 2026-09-06. This records planning evidence, not completed release tests.

## Primary sources consulted

- [Apple — Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution): distribution signature, executable hardening, timestamps and ticket requirements. Notarization is not App Store review. Applied in 377–380.
- [Apple — Resolving common notarization issues](https://developer.apple.com/documentation/security/resolving-common-notarization-issues): inspect actual notary logs and validate signatures; a submission alone is not acceptance. Applied in 379.
- [Apple — Creating distribution-signed code for macOS](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/): archive/export and distribution-signing reference for 377.
- [Apple TN2206 — macOS Code Signing In Depth](https://developer.apple.com/library/archive/technotes/tn2206/_index.html): nested-code/framework structure, inside-out signing and verification distinctions. Historical technical note used alongside current Apple guidance, not as the sole current policy source.
- [PyInstaller 6.16 feature notes](https://pyinstaller.org/en/v6.16.0/feature-notes.html) and [6.16 usage](https://pyinstaller.org/en/v6.16.0/usage.html): pinned worker-freezer bundle layout, architecture and macOS signing considerations. Applied in 372/377; retain framework/symlink structure and test actual signed execution.
- [Sparkle setup/security](https://sparkle-project.org/documentation/) and [publishing](https://sparkle-project.org/documentation/publishing/): local Keychain update key, incrementing builds, signed archives/feeds and appcast publication. Applied in 371/380/382. The inspected local pinned Package.swift identifies Sparkle 2.9.5, and generate_appcast/main.swift includes feed-signing behavior. No Sparkle upgrade is planned.
- [GitHub hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners): public-repository native arm64 runner choices. Labels/toolchain availability are checked again at implementation; CI proof is not interactive Finder installation proof.
- [GitHub releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases): release assets are the distribution surface rather than committing large installer binaries into source history.
- [GitHub GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token): Actions has an automatic repository-scoped credential. The planned CI needs read-only access; actual publication uses the local gh login, so no manual cross-repo token is required.
- [Demucs upstream](https://github.com/facebookresearch/demucs) and [maintainer statement](https://github.com/facebookresearch/demucs/issues/327#issuecomment-1134828611): the latter was verified through the GitHub API during planning. It states that model weights are separate from the MIT code licence and limited to scientific purposes. This is evidence requiring checkpoint-specific investigation, not a completed legal determination for the selected htdemucs artifact. Research/clearance remains slice 370's work; no publication permission is asserted here.

## Source inspection anchors

Read active project.yml/Info.plist, AppUpdateCoordinator and settings/command wiring; build/runtime/manifest/notice/proof scripts; archive/export/signing/readiness scripts; provisional/final DMG scripts; Apple submit/staple scripts; Sparkle key/configuration/generation/publication scripts; release_preflight; current shipping/package docs; runtime requirements/provenance/notice collector; current local proof records. The older shared packaging guide had already been reviewed in this conversation and supplies sequence/reference-layout context, not instructions to implement Electron or a second repository.

Specific fixes mandated by this audit: replace hard-coded template artifact/repository defaults; replace global Sparkle tool discovery; extend signing beyond Sparkle; refresh helper hashes after signing before outer seal; make acceptance records artifact-bound; remove publication rebuilding and unconditional overwrite; eliminate lexical newest ZIP/DMG selection; parameterize dmgbuild safely; distinguish pre-notary verification from final Gatekeeper assessment; finish hash locks and true cold CI; resolve test-host stalling and actual rights gates.

## Checklist mapping

| Existing shipping section | New slices |
| --- | --- |
| 1 identity | 370–371, 374 |
| 2 behavior/state/privacy | 371, 374, 382 |
| 3 dependencies/runtime/notices | 370, 372, 376–377 |
| 4 legal/support | 370–371 |
| 5 updater/repos | 371, 375–376, 380–382 |
| 6 versions/pre-Apple proof | 373–378 |
| 7 signing/notary/publication | 377–381 |
| 8 final install/update/archive | 381–383 |

## Planning verification contract

All 14 execution slices 370–383 have high-level outcome, exact file work, low-level behavior/flow, dependency/licence implications, verification/packaging impact and stop conditions. Source filenames were checked against the working tree; new files are explicitly planned, not assumed present. The master plan specifies ordering, same-repository feeds, local credentials, immutable artifact transitions and A/B visibility. Future evidence paths are not fabricated completed reports.

A local documentation checker verifies relative links resolve to existing documentation, every ordered slice exists, and required sections are present. Only documentation under docs/ is edited in this planning turn. Existing build outputs, application/runtime/release scripts, Git state and external accounts are unchanged by the plan. No key generation, repository creation, push, signing, notarization, stapling or publication occurred.

## Questions after planning

None required to start. Routine implementation choices are delegated. Rights research, clean interactive test access and native credential prompts are possible later blockers, not tasks assigned back to the owner preemptively. If model terms cannot be resolved from authoritative evidence, present the narrow unresolved issue and alternatives before distributing those weights.
