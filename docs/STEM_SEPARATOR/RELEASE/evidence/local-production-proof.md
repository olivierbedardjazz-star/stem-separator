# Local production proof — 2026-09-06

Owner-required order: local bundled production proof precedes GitHub clean-machine builds.

- Hash-locked Python environment reconstructed from an empty venv; all downloaded artifacts rehashed, source builds performed without network-enabled build isolation, pip dependency check passed.
- Runtime audit resolves all 35 native binaries' non-system dependencies inside the helper and checks arm64 and macOS 14 deployment floors. Removed two unused optional torchaudio SoX extensions with unresolved libsox loads. No model change.
- Offline 14-second, three-chunk inference passed with empty HOME, minimal PATH and network denied. Four finite stereo stem buffers verified. Cancel, parent EOF and invalid request tests passed.
- Optimized Release unit suite: 15 passed. Debug unit suite: 15 passed. Release UI workflow: passed after correcting the test's native-panel query to support both NSOpenPanel window and dialog representations.
- Local Developer ID-signed archive candidate: 0.1.0 build 100. All 35 helper Mach-O signatures verified; helper manifest regenerated after nested signing; outer bundle sealed and strictly verified.
- Provisional signed DMG built, mounted read-only and copied to an isolated installation folder. Installed app fingerprint matched the source candidate; signatures and actual offline inference passed.
- XCTest targeted the signed installed app by URL, without rebuilding or re-signing it. Full audio intake, destination cancel/retry, separation, output success, menu and Terms flow passed (37.8 seconds).

Logs remain in ignored build/StemRuntime, with artifact-bound records in release-evidence/0.1.0-100. Full UI recordings/hierarchies remain private. This is this Mac's production proof, not Apple notarization, Finder drag-and-drop, a quarantined public download or second hardware proof. Subsequent source changes require appropriate candidate renewal.
