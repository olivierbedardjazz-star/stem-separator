# Karaoke: implementation and acceptance plan

Local 0.1.2 MPS candidate, September 15, 2026. Published releases remain unchanged.

1. Domain and worker: introduce SeparationMode (stems/karaoke) in SeparationJob.swift. Propagate through SeparationStore, SeparationSession and StemWorkerProcess. Worker validates mode and echoes it; Swift validates exact expected output names. HTDemucs still predicts four sources, but karaoke sums drums+bass+other in memory and serializes only karaoke.f32le. Never serialize vocals or individual stems in karaoke mode. Existing chunking and MPS contract remain unchanged. No dependency or licence changes. Stop on protocol mismatch or nonfinite audio.
2. Export: StemOutputWriter validates the mode-specific manifest, scans peak and uses existing PCM24 writer. Karaoke atomically renames one WAV into the selected folder as <name> - Karaoke.wav, with exclusive numbered collision handling. Four-stem folder behavior stays intact. Original input is never modified. Stop on cancellation, corrupt audio, disk failure or unsafe paths; never expose partial final output.
3. UI: reuse TemplatePrimaryActionButton directly beside Separate Stems in StemOutputPanelView. Both require valid audio and share picker/job/updater exclusion. Preserve pulse per action; cancel remains available during either mode. Generic destination picker, mode-specific completion and Finder reveal of the single file. No settings migration, audio history or menu changes needed.
4. Storage: JobWorkspace cleans prepared input/raw output on all exits; recovery keeps tracking metadata if destination cleanup cannot complete, retries next launch, and protects live/unmarked workspaces. Log cleanup failures without paths. Check temporary volume capacity independently. Working input and karaoke PCM are temporary files during processing; they are not retained as a cache. Abrupt termination requires recovery; disconnected/read-only storage cannot be physically cleaned until available. No promise of secure erasure or control over macOS swap/backups.
5. Verification: numerical mixing test with arbitrary source ordering and conspicuous vocal values; bundled MPS karaoke end-to-end, only one WAV, format/duration, original unchanged, workspace absent; naming collisions, invalid manifests, cancellation, recovery with unavailable destination; existing native and worker regression tests. Rebuild bundled helper and local Release app. Record actual results here. Stop if runtime tests fail; do not publish merely on compilation success.

Shipping impact: same bundled runtime/model/licences, no downloads or new dependencies. New helper/app must pass release signing, clean CI, notarization and updater gates before distribution. This task delivers a local test build, not a replacement for the published DMG.

## Completed verification

- Bundled runtime rebuilt from locked dependencies; audit: 35 Mach-O binaries, zero failures.
- 19 native XCTest cases passed, zero failures. Includes two 14-second MPS karaoke exports (numbered collision, PCM24 format/duration, unchanged input, workspace removed), karaoke cancellation, corrupt output/manifest rejection, destination-picker cancellation, unavailable-destination metadata retention and retry, and existing four-stem regressions.
- 16 release/tool unit tests passed, including arbitrary-source-order mixing and vocal exclusion.
- Frozen helper ran both modes with network denied, empty HOME and minimal PATH. Karaoke produced exactly one finite `karaoke.f32le`; stem mode produced exactly the four expected files. Both completed three real inference chunks.
- Release build succeeded. Native UI inspection confirmed both primary buttons side by side, initially disabled without audio; existing shell/brand/footer preserved. Final UI movement of Cancel into the progress row was compiled in Release; automated suite covers underlying cancellation. No real-song listening assessment performed.
- Local build: `build/MPSCandidate/DerivedData/Build/Products/Release/Stem Separator.app`.
- Evidence: `build/KaraokeCandidate/{runtime-build.log,native-tests.log,release-tests.log,worker-karaoke.log,worker-stems.log,release-build.log}`.
- No release publication, signing/notarization or replacement of existing release handoff artifacts.

## Operational limits

No individual model source, including vocals, is written in karaoke mode. Prepared input and one karaoke PCM file exist only in the job workspace during processing. Normal success/cancel/error cleanup is tested. On deletion permission failures the owned workspace is retained and the failure logged for recovery; an inaccessible external volume cannot be cleaned until it returns. Superseded by release slice 1: recovery records now persist in a metadata-only Application Support journal, independent of temporary workspace purging. Pending cleanup is shown in the UI and retried on disk mount, launch and the next job. This is not a secure-erasure guarantee. No hidden audio is deliberately retained for history, caching or reuse. Model bleed can remain audible; the feature excludes the estimated vocal source rather than guaranteeing perfect voice removal.
