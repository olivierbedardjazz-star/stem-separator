# Slice 374 — Local Debug, Release and failure proof

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 371–373. Outcome: the configured candidate works through native UI and runtime paths on this Mac before any public binary release.

## Exact file work

Change `Tests/SeparationTests.swift`, `UITests/StemSeparatorUITests.swift`, `runtime/test_worker.py`, `runtime/test_worker_control.py`, `scripts/verify_packaged_runtime_launch.sh`, and `scripts/run_clean_packaged_runtime_proof.sh`. Create `scripts/run_local_product_proof.sh` and `docs/STEM_SEPARATOR/RELEASE/evidence/local-product-proof.md`. Repair only demonstrated defects in `TemplateApp/Separation/Application/SeparationStore.swift`, `SeparationSession.swift`, `TemplateApp/Separation/Infrastructure/AudioPreparationService.swift`, `StemWorkerProcess.swift`, `JobControl.swift`, `JobWorkspace.swift`, `StemOutputWriter.swift`, `TemplateApp/App/AppLifecycleCoordinator.swift`, `AppCommandDispatcher.swift`, `AppUpdateCoordinator.swift`, or `TemplateApp/App/TemplateAppApp.swift`; document exact edits if required. Build/project test-host configuration may need changes in `project.yml`, then regeneration.

## Low-level validation and UI behavior

Resolve the previous Xcode test-host stall by inspecting the actual launched path, test injection/signing, duplicate app identity and test logs. Keep Debug/ad-hoc test accommodations scoped to those configurations; never use disabled hardened runtime as production proof. Standalone harness success remains supporting evidence, not a replacement for app-hosted/UI tests. Run sequentially when tests share an app identity and never rebuild an app bundle during its active separation.

Exercise the settled UI: one drop or native audio picker; X clears only the reference and has hand cursor/shared motion; invalid/multiple inputs fail clearly; primary action disabled without valid audio; destination picker every time; cancel picker starts no work; double click does not create two jobs; actual progress; cancellation at preparation/loading/inference/writing; usable results before success; Finder reveal points to the committed folder. No output chooser is restored to the panel. Verify 🎁 Surprise label with unchanged source identifier.

Exercise native WAV/AIFF/MP3/unprotected M4A, mono/stereo, 44.1/48 kHz and supported resampling, Unicode names, short/silent input, multi-chunk audio, a representative full track and upper duration boundaries. Check output frame counts, 24-bit stereo/44.1 kHz, finite samples, four files, shared attenuation and no source mutation. Measure wall time, peak memory and disk footprint at several durations; record practical minimum-RAM claims instead of extrapolating from a 14-second test.

Inject denied/unavailable destination, source disappearance, corrupt input, incomplete/nonfinite worker output, low space, interrupted writes, existing-name collisions, external/read-only locations, stale bookmark, worker EOF/exit/protocol error and parent death. Assert no partial result is presented as success and cleanup only deletes owned staging. Verify a live workspace cannot be swept by another app instance. Tests that simulate disk failure do not fill the user's disk or change personal-folder permissions.

Verify current error diagnostics preserve a bounded phase/domain/code without private descriptions/paths. Add controlled failure evidence. Do not claim the earlier unknown failure was reproduced or fixed unless it actually is. Test quit/cancel/update mutual exclusion, no active-job restart, menu cleanup after state changes, all themes/legal modals/footer and unchanged primary motion.

## Dependencies and packaging

Use synthetic/rights-cleared fixtures for automation; owner music remains local and is never an artifact. No new product dependencies. Run native Debug, unsigned optimized Release, and moved-bundle offline helper checks, using exact app paths. Capture build/configuration/identity in every report to prevent confusing stale app copies.

## Exit evidence and stop conditions

Required: actual XCTest/unit result, UI result with limited sanitized captures, full native workflow, negative-path results, measured resources, and explicit OS/hardware. Any stall, crash, race, partial output, privacy leak, motion/menu drift, or unexplained reproducible failure blocks completion. Lack of another physical Mac is recorded here and addressed in 378/381, never relabeled as a local test pass.
