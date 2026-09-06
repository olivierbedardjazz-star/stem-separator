# Stem Separator — single-repository release plan

Prepared 2026-09-06. **Execution authorized and underway.**

Current order override: owner explicitly requires a complete local bundled Release and signed installation proof before any GitHub build. Local signing/installation therefore precede public source/CI; accepted exact-source CI remains required before Apple submission/publication.

Current override: the owner completed the model assessment and authorized distribution of checkpoint 955717e8 under the historical July MIT grant. See [owner assessment](evidence/model-owner-assessment.md). Baseline descriptions below describe the planning snapshot; execution evidence records subsequent changes.

Workspace: `/Users/oliviergrenierbedard/Desktop/My_Musical_Brain/STEM_SEPARATOR`. File paths in these specifications are relative to that workspace unless explicitly stated. This documentation turn creates no repository, keys, builds, signatures, submissions, or releases.

## Outcome and settled decisions

Ship a free native SwiftUI macOS app for Apple Silicon, with Python/Demucs and one four-stem model bundled. No Python, Homebrew, ffmpeg, command-line tools, account, payment, or model download is required on the user's Mac. Keep the current single-file workflow: choose/drop audio → enabled Separate Stems button → native destination picker → real progress → four WAV files and Finder reveal. Keep the exact brand primitives, logo/icon already created, banner/social destinations, footer/legal behavior, and minimal menus. The visible fourth label is 🎁 Surprise; the model source and existing output file remain `other` / `other.wav` unless the owner requests a filename change.

One **public** repository, `olivierbedardjazz-star/stem-separator`, contains reviewed source, CI and documentation. Its GitHub Releases hold the installer DMG, Sparkle ZIP and signed appcast. There is no second updates repository, payment service, or cross-repository publish token. Public source visibility does not itself grant a new licence to the project's code, artwork, or third-party model.

The local Mac builds the distributable candidate, signs, submits to Apple, staples, prepares assets and publishes via the existing GitHub CLI login. GitHub-hosted Apple Silicon jobs independently build/test the same source without signing credentials. Do not register the credential-bearing Mac as a public-repository self-hosted runner. No manually configured repository secrets are needed in this design. Local Keychain access prompts remain possible; never print/export secrets into logs or Git.

## Defaults chosen for implementation

| Setting | Planned value |
| --- | --- |
| Product / scheme / module | Stem Separator / TemplateApp / TemplateApp |
| Main / helper bundle ID | `com.oliviergrenierbedard.stemseparator` / `com.oliviergrenierbedard.stemseparator.worker` |
| Source and release repository | `olivierbedardjazz-star/stem-separator` |
| Stable feed | `https://github.com/olivierbedardjazz-star/stem-separator/releases/latest/download/appcast.xml` |
| First-install page | `https://github.com/olivierbedardjazz-star/stem-separator/releases/latest` |
| Local Sparkle Keychain account | `stem-separator-ed25519` |
| Apple team / profile | Existing `5SVUWU2ZGY` / `notary-profile`; revalidate when used |
| Support | Existing `info.mymusicalbrain@gmail.com`; GitHub Issues for non-sensitive bugs |
| Initial proof pair | A `0.1.0` build `100`, B `0.1.1` build `101`; reserve only after checking no conflict |
| Architecture / target floor | Native arm64 / macOS 14, subject to actual minimum-OS runtime proof |
| Artifact base | `Stem-Separator-<version>-<build>-arm64` |
| Source licensing default | Preserve existing ownership/third-party licences; do not silently apply MIT to everything |

These are chosen future inputs, not claims that project.yml has already changed. The repo name can fall back to a clear variant only if unavailable; never overwrite or adopt an unrelated existing repository. An earlier local build is not a supported Sparkle predecessor: the stable ID starts a new preferences domain. No paid features or source-licence expansion is inferred from free pricing.

## Observed baseline and concrete gaps

- Working local Release app; owner confirmed a successful separation on September 6. Debug and optimized standalone native diagnostics also processed three chunks and saved four WAVs. These are not notarization or clean-device proof.
- Main ID still ends in `.local`; feed/key are placeholders. Sparkle revision `79bc9e872948e47877e76f194cb0c8e0412b0b90` resolves to 2.9.5 in the inspected checkout; its generator supports signed feeds. `SURequireSignedFeed` and `SUVerifyUpdateBeforeExtraction` are already enabled.
- No `.git` or `.github` workflow existed at inspection. GitHub login and local Developer ID were visible; read-only notary history authenticated with `notary-profile` earlier in this session. Credential availability can change and does not prove signing the new runtime.
- Runtime: CPython 3.11.16, Demucs 4.0.1, Torch/Torchaudio 2.5.1, NumPy 1.26.4, PyInstaller 6.16.0; exact model/Python hashes in `runtime/provenance.json`. Python requirements are version-pinned but lack artifact hashes. Collection currently regenerates legal text with evaluation-only wording.
- Existing signing finalizer covers Sparkle only. Existing runtime audit checks arm64 presence and absolute dependencies, but does not fully resolve all relative loads or prove every nested signature. Its minimum-version tuple handling needs normalization.
- Signing changes runtime bytes after the embed-time helper hash manifest was produced; the release plan explicitly regenerates the helper manifest after nested signing and before outer sealing.
- Template artifact names, lexical newest-file selection, automatic publication-time asset rebuilding, unconditional asset overwrite, and stamp-only notarization handoffs are unsuitable for the release lane.
- Xcode-hosted tests stalled during the latest diagnostic run; independent source-level diagnostics passed. Resolve and rerun the real app-hosted tests, not just the standalone fallback.
- Model redistribution remains unresolved. An upstream maintainer's 2022 comment distinguishes model weights from MIT code. Research its applicability to this specific later checkpoint; neither free pricing nor a successful model download settles it.

## Ordered slices

| Slice | Outcome | Dependency |
| --- | --- | --- |
| [370](370_RIGHTS_BASELINE_AND_PUBLICATION_BOUNDARY.md) | Baseline, rights inventory and safe public-source boundary | Start |
| [371](371_RELEASE_IDENTITY_KEYS_AND_LEGAL.md) | Stable identity, local update key, truthful policies | 370; model wording waits for rights conclusion |
| [372](372_REPRODUCIBLE_RUNTIME_AND_TOOLCHAIN.md) | Complete reproducible runtime and build-tool closure | 370 |
| [373](373_RELEASE_CONFIGURATION_AND_ARTIFACT_RECORDS.md) | Explicit release inputs and verified artifact handoffs | 371–372 |
| [374](374_LOCAL_DEBUG_RELEASE_AND_FAILURE_PROOF.md) | Product and packaging proof on this Mac | 371–373 |
| [375](375_PUBLIC_REPOSITORY_AND_SOURCE_REVIEW.md) | Safe first public source commit and repository | 370, 374; workflow authored in 376 |
| [376](376_GITHUB_CLEAN_BUILD_PROOF.md) | Exact-commit cold-cache Apple Silicon CI evidence | 375 |
| [377](377_NESTED_SIGNING_AND_RUNTIME_PROOF.md) | Developer ID-signed app with working bundled worker | 370 rights cleared, 374, 376 |
| [378](378_PROVISIONAL_DMG_INSTALLATION.md) | Installed signed candidate works before Apple submission | 377 |
| [379](379_APP_NOTARIZATION_AND_STAPLING.md) | Accepted and stapled exact app | 378 |
| [380](380_FINAL_DMG_AND_SPARKLE_ASSETS.md) | Final notarized DMG and signed updater assets | 379 |
| [381](381_PUBLICATION_AND_CLEAN_INSTALL.md) | Published exact assets and downloaded-install proof | 380 |
| [382](382_TWO_VERSION_UPDATE_PROOF.md) | Real installed A → B upgrade | 381 for A; repeat release gates for B |
| [383](383_RELEASE_HANDOFF_AND_MAINTENANCE.md) | Durable evidence, repeatable release operation | 382 |

Author the CI workflow before the first push so that push can run it; the table describes proof completion order. Source-only publication can proceed while model redistribution research continues only when the public tree and CI artifact policy exclude materials not cleared for that use. No distributable model-bearing asset crosses the rights gate.

## Architecture of the release lane

```text
reviewed source + locked inputs + release configuration
   ├── local Debug/Release functional proof
   └── public source commit → isolated GitHub build/tests → exact-SHA evidence
                    ↓
local archive/export of same source → nested signing → helper manifest → outer signature
                    ↓
signed runtime proof → provisional DMG → installed workflow proof
                    ↓
submit exact app ZIP → Apple Accepted → staple/validate exact app
                    ↓
final DMG (sign → Accepted → staple) + Sparkle ZIP + signed appcast
                    ↓
reviewed release record → GitHub draft assets → publish → anonymous verification
                    ↓
real downloaded DMG installation → A→B Sparkle installation → archive evidence
```

App code remains UI → store/session → native audio/process/output adapters. Release scripts do not become app runtime dependencies. New Python release utilities only run on build machines; no general framework or new application target is required. Common configuration and one versioned JSON release record replace repeated implicit shell defaults.

The signed candidate is built once per source/version. A later edit invalidates its dependent proofs. Code signatures and stapling are deliberately recorded transformations: do not demand byte-identical pre-sign/post-sign or pre-staple/post-staple bundles. Compare immutable source/model/config identities across transformations and store hashes for each stage. After app submission only ticket stapling is permitted; no source/resource/signature edits.

## Evidence and approval boundaries

Sanitized summaries live in `docs/STEM_SEPARATOR/RELEASE/evidence/`. Full local records/artifacts live in ignored `release-evidence/<version>-<build>/` inside this workspace, outside disposable `build/`. Keep a durable backup when an owner-controlled backup is available; do not invent a storage account or commit credentials. Every record names source SHA, tool versions, app identifier/version, input hashes, commands/outcomes, time, hardware/OS and actual limitations. Public logs never contain user audio names, bookmarks, paths, secrets or test music.

A clean CI runner proves build independence. It does not prove Finder, user prompts, macOS privacy identity, physical device performance, or a normal quarantined download. A fresh local account helps preference isolation but is not a second hardware/OS configuration. Obtain available clean-account/second-Mac evidence and record precisely what was and was not exercised. Do not fabricate a clean-machine pass when no suitable interactive machine is available.

The owner has delegated routine defaults and requested this plan before execution. This turn is documentation only. During later authorized execution, progress autonomously within scope; stop only the affected work for a real failed gate, unavailable account/OS interaction, or unresolved rights. Do not turn inherited two-repository instructions into repeated approval requests.

## Version and publication policy

Use a production-feed A/B pair to avoid shipping a test-feed variant with different bytes: both A and B are fully signed/notarized, normal releases in the same public repository, using the same permanent key/feed/ID. A is the initial validation release, B verifies updating and becomes the recommended download. These releases are public, even before broad announcement; they are never described as private. No draft or prerelease is assumed reachable through `releases/latest`. A feed containing only the latest supported item is sufficient for v1; keep old binary assets immutable. Choose no binary deltas initially.

User-facing first installation is the DMG. ZIP is a Sparkle transport artifact, not a second installer tutorial. Publish complete asset sets before promoting latest. A new version uses a new source commit/tag/build, never replacement bytes behind an already released version URL. A failed release is corrected forward with a higher tested build; publication failure does not justify disabling signature checks.

## Questions and unresolved work

No preference question is required to begin implementing these slices. The executor owns repository names, scripts, keys, ordinary identity defaults, and investigation. Potential later blockers are model redistribution permission, required native credential prompts, and access to an interactive clean test environment. If authoritative licence evidence remains ambiguous, present the exact evidence and feasible alternatives rather than claiming permission or silently replacing the model. Read [384 references](384_RESEARCH_AND_PLAN_VALIDATION.md) for researched requirements and plan verification.
