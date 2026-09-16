# Performance and storage validation plan

Scope: test current 0.1.1/101 source and unchanged signed worker; do not modify shipping code, bundle, model, dependencies, preferences, release configuration or publish anything. Findings inform a later release (version not selected yet).

## Facts and questions

Current worker explicitly requests CPU. Torch 2.5.1 reports MPS built/available on this M1 Max/64 GiB machine. Availability is not model compatibility or a speed claim. Chunking bounds per-forward activations, but full input, accumulator/output, normalization and temporary tensors remain duration-dependent. Previous 2.58 GB maximum RSS was measured over a synthetic harness, not a worst-case app bound or a low-memory-device qualification.

## Ordered slices

1. **Reproducible baseline and instrumentation.** Create Tests/Performance/NativeProbe.swift and run_suite.py. Compile Domain, Infrastructure and SeparationSession with one test-only generated override of JobWorkspace.root (mandatory STEM_PROBE_TEMP); all other logic unchanged. Foundation ignores TMPDIR for this root on this host. Build using Swift 6/arm64/macOS14/optimization into an isolated command-line test host. Invoke the exact signed final worker by explicit path. This avoids the previously observed Xcode Debug-host launch issue; it does not replace SwiftUI testing. Record input checksum, source hashes, device/OS, phase timestamps, sampled parent/worker RSS separately, job/destination bytes and output format validation. No instrumentation inside the production app. Sources/model remain private test inputs; use synthetic audio only. Stop on nonfinite/invalid output, worker failure, timeout, >12 GiB sampled process-tree RSS, >1 GiB system swap growth or <8 GiB free project space.
2. **Duration/memory baseline.** Sequential full native preparation/inference/transactional WAV runs: 14 sec warm-up, three 3-minute repetitions, one 10-minute and one 20-minute track. Generate bounded-buffer deterministic stereo PCM fixtures. No fixture generation or post-run output scanning in timed separation duration. Report median/range for repetitions, per-stage timings, memory maximum and temporary-byte maxima. 250 ms polling can miss brief spikes, and summed RSS can double-count shared pages; do not call it physical footprint. No unmeasured 8/16 GiB hardware guarantee. Delete generated fixtures/stems after checking results.
3. **Sampling profile.** Capture a separate short native worker stack sample during actual chunk execution. Keep profiler overhead out of baseline runs. Distinguish process-start/model-load/native DSP/WAV-write costs. Sampling indicates hotspots, not a complete Instruments allocations/leaks or energy study.
4. **MPS compatibility experiment.** `Tests/Performance/probe_mps.py` loads the exact hash-verified checkpoint through pinned development runtime, runs identical CPU and MPS inference settings with fallback disabled, synchronizes GPU timing, checks finite dimensions and reports numerical differences if MPS succeeds. Do not alter production CPU protocol. If unsupported operators/complex tensors occur, record incompatibility and stop that candidate. Never enable CPU fallback or disable memory safeguards to manufacture success. If compatible, later repeat representative music quality/performance tests and prove frozen/nested-signed/offline packaging before adoption.
5. **Cleanup correctness.** Standalone native probe uses actual JobWorkspace code, separate TMPDIR, synthetic-owned destinations only. Exercise repeated normal destruction; crash then recover; live and unmarked workspace protection; accessible staging recovery; deletion denied then retry; inaccessible destination and malformed bookmark recovery; cancellation during real inference/writing; malformed worker output; destination preflight failure. Record current defects explicitly, not passing future expectations. Do not sweep real app workspaces or user output folders.
6. **Controlled capacity faults.** `Tests/Performance/capacity_tests.py` uses a small disposable disk image created specifically under build/Performance, never fill the physical disk or detach user volumes. Test insufficient destination space, then insufficient temporary-volume space with a roomy destination. Unmount/delete only owned image in finally. Report phase of refusal and remaining files. Current destination-only preflight is expected to miss the second case until native conversion writes fail. Disk-image tests approximate separate-volume faults; they are not physical-device/iCloud/reconnect certification.
7. **Storage-soak and acceptance.** Verify no owned job/staging leftovers after successful/cancelled sessions and record normal intentional output files separately. Compare relevant Application Support/cache/temp observations. Isolated source tests do not prove all Sparkle/macOS cache behavior. Future tests: force-kill at every write/commit transition, removable-volume loss/reconnect, stale bookmarks, sleep/reboot and 8/16 GiB physical hardware, representative licensed musical material, Instruments physical-footprint/leaks/energy, repeated upgrades.
8. **Results and follow-up fixes.** Write 002_RESULTS.md with actual measurements, failures, limitations and prioritized proposed fixes. Proposed production changes: durable minimal cleanup journal with retry after volume return; log sanitized cleanup failure reason; preserve ownership/live-lock protection; independently budget temp/output volumes; audit partial initialization cleanup; then investigate measured CPU/allocation bottlenecks or MPS alternatives. Separate implementation authorization/release gates from this measurement task.

## Dependencies, privacy and packaging

No new runtime dependencies or licence changes. Python harness uses standard library; MPS probe uses already pinned NumPy/Torch/Demucs. Swift probe links platform frameworks and exact local production sources. Tests and results are development-only; no change to Xcode source list or shipping bundle. No owner music, file bookmarks, raw audio or absolute user paths in public results. Detailed local logs remain ignored under build/Performance. Retain small result reports, remove generated bulk data at end.

## References

- PyTorch MPS overview: https://docs.pytorch.org/docs/stable/notes/mps.html
- Exact installed code and runtime/worker/stem_worker.py take precedence over latest-library behavior.

## Reproduction commands

Run from the repository root, sequentially, with the retained pinned developer runtime:

```sh
build/StemRuntime/portable-venv/bin/python Tests/Performance/build_probe.py
build/StemRuntime/portable-venv/bin/python Tests/Performance/run_suite.py storage
build/StemRuntime/portable-venv/bin/python Tests/Performance/run_suite.py baseline
build/StemRuntime/portable-venv/bin/python Tests/Performance/run_suite.py profile
build/StemRuntime/portable-venv/bin/python Tests/Performance/probe_mps.py
build/StemRuntime/portable-venv/bin/python Tests/Performance/capacity_tests.py
```

`build_probe.py` records source hashes and generates the single workspace-root override under ignored build/Performance. It does not edit JobWorkspace.swift. Baselines use the exact signed worker but a test-only optimized native host, not SwiftUI. Run backend/capacity experiments separately from timing baselines to avoid competing workloads. Each session removes its own fixture/output tree on exit. Keep small measurements; do not retain generated audio.

Current results and incomplete coverage: [002_RESULTS.md](002_RESULTS.md). After an interrupted baseline, run cancellation cases separately; run_experiments.py executes storage/profile/MPS/capacity/boundary follow-ups sequentially, without repeating baseline inference.
