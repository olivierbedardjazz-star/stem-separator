# Slice 382 — Real installed A → B Sparkle proof

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 381 for A; repeat candidate gates for B. Outcome: an installed older app securely updates itself and still separates audio afterward.

## Exact file work

Change `project.yml` and regenerate `TemplateApp.xcodeproj/project.pbxproj` for B's marketing/build version. Create `docs/STEM_SEPARATOR/RELEASE/notes/0.1.1.md`, `docs/STEM_SEPARATOR/RELEASE/evidence/two-version-update.md`, `Tests/Release/test_update_feed.py`, and `scripts/verify_update_transition.sh`. Change `TemplateApp/App/AppUpdateCoordinator.swift`, `TemplateApp/App/AppCommandDispatcher.swift`, `TemplateApp/App/AppLifecycleCoordinator.swift`, `TemplateApp/Separation/Application/SeparationStore.swift`, `Tests/SeparationTests.swift`, or `UITests/StemSeparatorUITests.swift` only for demonstrated defects. Use existing 377–381 tools, not a parallel release implementation.

## Two concrete versions

A: 0.1.0 / build 100 / tag v0.1.0. B: 0.1.1 / build 101 / tag v0.1.1, subject to prior conflict checks. Both are normal public releases with the permanent ID, same signing identity, same Sparkle key and same stable feed. B may be a transparent packaging/update-validation patch; don't invent feature changes. Neither version points to a temporary feed. Until the pair passes, describe release validation as in progress rather than fully complete.

## Low-level flow and state assertions

1. Install A from the final DMG following 381. Verify its actual Info.plist/Team ID/helper manifest. Set a non-default theme, accept legal notice, choose an output destination, and successfully produce four stems. Record only non-sensitive preference keys/values needed to prove migration; don't export real bookmark bytes into logs.
2. With A still the latest feed item, invoke Help > Check for Updates and verify honest no-update behavior. Test offline/unreachable feed separately; it must be an error/unavailable state, not a no-update claim, and must not block separation permanently.
3. Prepare B from a new exact commit with monotonically larger CFBundleVersion. Repeat local/CI proof, explicit nested signing and signed helper execution, provisional install, app/DMG acceptance and stapling, final artifacts and publication. If provisional testing installs B over A, preserve A and reinstall its exact already verified final artifact afterward; do not confuse test installation with updater success.
4. Launch installed A and publish B's complete signed asset set as latest. A downloads appcast, validates it, offers B, downloads/validates ZIP, installs and relaunches as B through Sparkle. Do not manually install B during the transition. Record old/new PID/path/build plus UI outcome and downloaded archive identity.
5. Verify theme/legal-version behavior and usable output-bookmark preference survive; stale/unavailable bookmarks fail safely and prompt for destination. Source audio and previous stems remain untouched. No in-progress job auto-resumes. Run a new four-stem separation offline using B's bundled worker. Check next update uses the same stable feed/key and reports up to date.
6. Test separation/update exclusion: a running job or open destination picker prevents automatic/manual update start; active update session prevents new separation. Cancellation/failed download releases the busy state. Quit/relaunch/install ordering must not abandon a live worker or leave partial output.

## Negative security tests

Use isolated local fixtures/test instances for tampered archive, wrong Ed25519 signature, unsigned/altered appcast, wrong bundle ID, unsupported OS/architecture, non-increasing build and interrupted download. Never publish a malicious/broken feed as the production latest item just to test rejection. Prove checks using the pinned Sparkle implementation/integration where possible; pure XML parsing is supporting evidence, not proof that the real updater rejected an archive. Preserve all production signature settings.

## Dependencies/licences / packaging impact

A and B include the same approved payload unless a documented product change forces renewed licence/runtime proof. Both versions consume local signing credentials; no GitHub secrets. Keep both final DMGs/ZIPs and source tags immutable for recovery/testing. A normal public A release cannot be described as a private/internal build.

## Stop conditions

No genuine A→B installation, manual B installation mistaken for update, signature protection disabled, lost settings, wrong helper version, stuck busy state, active-job interruption, or failed separation after update. Completion requires observed installed transition and post-update behavior, not just a correct appcast.
