# Slice 371 — Stable identity, local keys and legal surfaces

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 370; production licence wording depends on its conclusion. Outcome: one permanent identity and one trusted update channel with credentials kept on this Mac.

## Exact file work

Change `project.yml`, regenerate `TemplateApp.xcodeproj/project.pbxproj`, change `TemplateApp/Info.plist`, `runtime/StemWorker.spec`, `TemplateApp/App/AppUpdateCoordinator.swift`, `TemplateApp/App/AppSettingsStore.swift`, `TemplateApp/Separation/Application/SeparationSession.swift`, `TemplateApp/UI/RootView.swift` only as needed for identity/state references, `scripts/bootstrap_sparkle_keys.sh`, `scripts/ensure_sparkle_keys.sh`, `scripts/locate_sparkle_bin.sh`, `scripts/configure_github_appcast.sh`, `docs/LEGAL/TEMPLATE_APP_TERMS.md`, `docs/LEGAL/TEMPLATE_APP_PRIVACY.md`, and `Tests/SeparationTests.swift`. Create `docs/STEM_SEPARATOR/RELEASE/evidence/identity-and-keys.md`. Existing `TemplateApp/UI/Components/AppLegalDocumentCatalog.swift` changes only if the document contract changes; keep existing resource filenames to avoid needless churn.

## Low-level work and data flow

1. Apply master-plan permanent app/helper identifiers and test-target identifiers. Keep project/scheme/module names internal. Start release A at 0.1.0/100 after conflict checks. Update OSLog subsystem consistently; scan active source/resources for `.local`, template text and wrong product identity. Do not rename protected visual primitives or reconnect excluded downloader code.
2. Select the tools under the current explicit DerivedData Sparkle artifact directory, verify the locked revision/checksum and tool version, and eliminate selection from unrelated global DerivedData. Inspect installed `generate_keys`/`generate_appcast` help rather than inventing flags.
3. Bootstrap `stem-separator-ed25519` once using the existing Keychain. Check for the account first; never rotate during normal builds. Commit only the derived public key. Verify it agrees between Keychain public readout, project.yml, generated project and built Info.plist. Record account name and public-key fingerprint, never private material. Keep existing Apple identity and `notary-profile`; no certificate export or GitHub secret creation.
4. Configure the master-plan HTTPS GitHub Releases feed. Preserve `SURequireSignedFeed` and `SUVerifyUpdateBeforeExtraction`. Strengthen configuration validation for actual owner/repository and a valid Ed25519 public-key length/encoding; reject credentials in URLs, unexpected host/path and placeholders. Existing AppUpdateConfiguration lives inside AppUpdateCoordinator.swift.
5. Preserve `AppCommandDispatcher → AppUpdateCoordinator → SPUStandardUpdaterController`. Separation and destination selection block update initiation; updater sessions block new separation/intake. Before the first release exists a network/missing-feed error is expected, not a false “up to date.” Verify a correctly signed no-newer-item feed later in 382.
6. Use the permanent bundle ID as a clean first-run boundary from the `.local` evaluation build. Retain `stem-separator.v1.theme`, `.responsible-use-version`, and `.output-bookmark` keys within the new domain. Do not import unrelated apps' settings or automatically restore old jobs. A→B uses the same domain and preserves valid settings/bookmarks. If revised legal consent meaning requires it, increment responsible-use version deliberately before freeze.
7. Finalize free-app Terms and Privacy to describe actual local audio processing, temporary files, stage/domain/code diagnostics, support contact and GitHub/Sparkle update traffic. Remove private-evaluation clauses only after clearance. Do not promise that updater network requests send no metadata. Keep banner/social destinations and exact legal presentation behavior.

## Dependency/licence implications

No new runtime. Same pinned Sparkle, model and UI assets. The key is a local release credential, not an app-bundled secret. Keep third-party terms separate from the source-code licence.

## Tests and packaging impact

Verify built app/helper IDs and version values, icon sizes, About text, footer links, full Terms/Privacy resources, and exact brand baseline. Test malformed keys/feeds, missing key, mismatched key, valid stable URL, wrong repository, and updater/job mutual exclusion. Test fresh stable-domain settings and A→B persistence; no automatic evaluation migration is required. Rebuild all subsequent candidates when any embedded identity/key/legal value changes.

## Stop conditions

Key mismatch/missing private key, unexpected existing identity, unverifiable asset provenance, unresolved production legal claims, accidental cross-app preferences, or changed protected UI constants. Do not satisfy failed updater tests by weakening signature requirements.
