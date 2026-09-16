# Local MPS candidate — 0.1.2 / build 102

Status: source implementation and local verification, not a published release. User approved retaining the exact four-stem HTDemucs checkpoint and its required internal chunking, and raising the minimum to macOS 15.1. The shipped 0.1.1/101 CPU artifacts and sibling STEM_SEPARATOR-RELEASE handoff remain immutable.

## Implementation delta from 0.1.1

- `runtime/artifacts-lock.json` and `requirements-lock.txt`: Torch/Torchaudio 2.5.1 → 2.6.0, exact CPython 3.11 macOS arm64 wheels fetched from PyPI and SHA-256 checked. All other pinned packages unchanged; `pip check` passed. Existing interpreter and checkpoint/hash/licence assessment unchanged.
- `runtime/worker/stem_worker.py`: request device must be `mps`; force framework CPU fallback off before importing torch; check macOS >=15.1 and `torch.backends.mps.is_available()`. Unavailable returns error `mpsUnavailable`, exit 21. Ready/result include device `mps`. `apply_model` explicitly uses MPS. ProgressPool synchronizes GPU work before publishing each completed-chunk event. Retain CPU input/output accumulation, shifts=0, 7.8-second split=True chunks, overlap=.25 and four outputs. Demucs explicitly transfers spectral operations to CPU; this is GPU model inference, not a claim that every operation or I/O occurs on GPU.
- `TemplateApp/Separation/Domain/SeparationJob.swift`: optional event device field. `Infrastructure/StemWorkerProcess.swift`: send mps request, require mps ready/result and display the unavailable-GPU/macOS requirement message. No silent whole-job CPU retry.
- `project.yml` and generated Xcode project: version 0.1.2/102; all native targets macOS 15.1. Helper spec and Packaging/release-config.json agree on OS floor. Existing identity, themes, motion, menus, footer/legal interaction and output naming remain unchanged.
- `runtime/provenance.json`, inventory and full notices refreshed. `collect_notices.py` clears each currently installed distribution's prior collected directory before recopying, preventing stale 2.5.1 licence filenames. New Torch BSD notices and Torchaudio licence included. Runtime audit still finds 35 native files with no escaping/unresolved dependencies; its permitted OS floor is now 15.1.
- `.github/workflows`: next-version matrix is macOS 15/Xcode16.4 and macOS 26/Xcode26.3. Public installer checks likewise use15/26. GitHub runner availability is not a GPU guarantee.
- `runtime/test_worker.py`: validates explicit MPS device and finite four-stem results. Normal local/release invocations require real inference success. Only explicit `--allow-unavailable` permits exit21 with exactly mpsUnavailable/no outputs, logging **NOT TESTED: MPS inference**. Hosted scripts use that option; local signing/installation release gates do not. Native GPU-dependent tests skip explicitly when no Metal device exists; other failures do not become skips.
- `runtime/test_worker_backend.py`: deterministic CPU-request rejection and simulated no-GPU/old-OS failure cases. `Tests/Release/test_worker_mps_contract.py`: progress waits for synchronization; synchronization failure cannot advance progress. No extra shipping dependencies.

## Local evidence

Ignored `build/MPSCandidate` retains wheel identities, candidate experiments, build/audit/test logs and local apps. The local Release app is `build/MPSCandidate/DerivedData/Build/Products/Release/Stem Separator.app`; it is Release-optimized and bundled, not Developer-ID-signed/notarized for distribution. Debug test app is under `build/MPSCandidate/DebugTests`.

Passed:

- Isolated Torch 2.6 CPU/MPS comparison of the same synthetic 14-second fixture and checkpoint. Both finite, exact four-source dimensions. Max absolute difference 3.527384251356125e-7; RMS difference 1.7784177686053226e-8. This is numerical smoke coverage, not musical quality equivalence. The initial comparison had competing machine load and includes first-use GPU costs, so its timings are not a speed claim.
- PyInstaller bundle construction; 35-file native runtime audit without unresolved dependencies.
- Frozen MPS worker, empty HOME, minimal PATH and network denied; three completed chunks, four finite raw stems, exit0.
- Full native preparation → packaged MPS worker → transactional 24-bit WAV commit: 14-second fixture in 6.927s, inference 4.507s; original hash unchanged; exactly four full-length stereo44100 Hz/24-bit WAVs. Sampled RSS 1.17 GB excludes complete GPU-allocation accounting; do not compare it directly to CPU physical footprint. Separate developer MPS probe reported about 2.86 GB driver allocation after inference.
- Extended full native three-minute synthetic run: 30.758s total, 18.591s inference, 10.715s writing/commit; four valid WAVs, unchanged input, zero temporary jobs. This single observed run is not an all-device speed guarantee or controlled CPU/MPS benchmark.
- Native inference cancellation, parent EOF and malformed request checks; no committed outputs/owned temporary jobs after cancellation.
- 15 native XCTest tests, zero failures, local Debug test host successfully launched; 14 release-tool/contract unit tests, zero failures. Backend negative tests: 3 passed.
- Bundled legal and notice-resource checks, refreshed package inventory. Actual app Info.plist 0.1.2/102 and minOS 15.1 verified.

The earlier Torch 2.5 MPS result remains in build/Performance/mps.json; the successful 2.6 result is separately retained in build/MPSCandidate/torch-2.6.0-result.json. Historical benchmark/architecture records describe their tested version, not this candidate.

## What remains before distribution

1. Real-song listening/quality and repeatable CPU-reference comparisons under controlled load; maximum-duration and 8/16 GiB hardware coverage. The old 20-minute run was interrupted by a large concurrent Ollama workload; that is not a completed maximum-length qualification for either backend.
2. Resolve or explicitly review the known cleanup-journal and temporary-volume-preflight defects documented in 002_RESULTS.md. They were not silently folded into this backend change. Profile long-job CPU output allocations and total unified/GPU memory separately.
3. Complete local **Developer-ID-signed**, hardened, fully bundled installation/UI/MPS proof, including cancellation and updater coexistence. The app currently linked above is a local development build, not that signed gate.
4. Commit the exact candidate, then perform the clean hosted 15/26 builds. GPU-unavailable hosted results cannot substitute for the physical-Mac MPS proof. This task has not pushed or run GitHub CI.
5. New-version Apple submission, stapling, final DMG/ZIP/appcast, public asset verification and real 0.1.1→0.1.2 updater proof. Preserve Sparkle identity/key/feed. Ensure appcast minOS 15.1 excludes older systems; keep 0.1.1 downloadable for macOS 14 users.

No new runtime model licence decision is needed for this unchanged checkpoint; any later alternative model/runtime still requires its own provenance/licence/package review. Do not overwrite 0.1.1 releases or handoff files with this candidate.
