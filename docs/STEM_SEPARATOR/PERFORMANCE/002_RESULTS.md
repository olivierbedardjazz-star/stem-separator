# Performance and storage findings — September 6, 2026

## Scope and identity

Tests exercise the current 0.1.1/build101 signed CPU worker and the production Swift separation services in a separately compiled optimized native command-line host. This is not a SwiftUI-process memory measurement. A generated test-only copy overrides only JobWorkspace.root to isolate owned workspaces; shipping source, model, runtime and signed release bytes are unchanged. No new dependency, release, signing or publication was performed.

The machine is M1 Max, 64 GiB RAM, macOS 26.3.1(a). Fixtures are deterministic synthetic stereo 44.1 kHz/16-bit WAVs, not musical quality references. Four resulting files were checked for exact duration, stereo, 44.1 kHz, 24-bit PCM; the signed worker validates finite model outputs. Input hashes were checked before/after. Fixtures and output WAVs were removed after checks.

See [plan and reproduction](001_PLAN.md). Harnesses live in Tests/Performance. Detailed measurements, source hashes, stack samples and environment records remain under ignored build/Performance. Public-facing measurements below omit local paths and audio data.

## CPU timing and memory

| Input | Full native separation | Inference | Worker serialization + native WAV writing/commit | Peak sampled process-tree RSS | Peak observed temporary files | Final four WAVs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 14 sec warm-up | 9.35 s | 7.25 s | 0.90 s | 1.98 GB | 24.7 MB | 14.8 MB |
| 3 min, run 1 | 91.31 s | 79.25 s | 10.78 s | 2.40 GB | 317.5 MB | 190.5 MB |
| 3 min, run 2 | 85.44 s | 73.51 s | 10.54 s | 2.48 GB | 317.5 MB | 190.5 MB |
| 3 min, run 3 | 87.83 s | 75.66 s | 10.73 s | 2.56 GB | 317.5 MB | 190.5 MB |
| 10 min | 279.30 s | 243.42 s | 34.33 s | 5.08 GB | 1.058 GB | 635.0 MB |
| 20 min | Interrupted; no completed benchmark | — | — | No qualified peak | — | No completed output |

All completed baseline jobs left zero owned job folders and no hidden staging folders. Three-minute median: **87.83 s**; observed range **85.44–91.31 s**. These fresh-process runs use warmed filesystem caches, not reboot-cold launches. Timing excludes fixture generation, harness WAV inspection and synthetic-output deletion.

Memory units above are decimal. RSS was polled every 250 ms, parent and descendants separately and summed at each sample. This can miss short spikes, does not measure all GPU allocations, and can double-count shared resident pages. It is not physical-footprint/allocated-memory accounting or a proven upper bound. The old time-l maximum RSS of approximately 2.58 GB is not a song-length-independent limit.

For 10 minutes, the largest observed worker RSS was 5.07 GB as output serialization began; native host maximum was 1.71 GB later during WAV writing. These maxima are not simultaneous and must not be added. Full input/normalization, full-output accumulation/denormalization and serialization copies scale with duration even though each model forward pass is chunked. At 20 minutes, four stereo float32 raw stems alone occupy approximately 1.69 GB, before input/model/activation/temporary tensors.

## Interrupted long test and shared-machine limits

The 20-minute attempt was stopped after approximately 8m32s of worker elapsed time. A concurrent Ollama llama-server occupied roughly 41 GiB RSS; global swap grew from an earlier observed 231.56 MiB to 5.9 GiB, and reached 8242.94 MiB at the stop snapshot. Global swapping cannot be attributed to Stem Separator alone. Low sampled RSS under compression/paging is not proof of low memory demand.

Only our benchmark was stopped. The unrelated model was left running and owner input was requested before unloading it. The clean maximum-length run remains pending available memory; no completed 20-minute result or 8/16 GiB compatibility is claimed. Later profiling/MPS probes were useful for code paths/compatibility, but their elapsed times are excluded from speed comparisons. The reusable native harness now stops on >12 GiB sampled process-tree RSS, >1 GiB growth in system swap, <8 GiB project free space or a 30-minute timeout. These are safety guards, not rigorous attribution of system pressure.

## Profiling findings

A separate 60-second fixture produced a five-second worker sample and a three-second native-writer sample. Sampling overhead and competing memory load exclude its 105.85-second elapsed result from the baseline table.

Worker samples show convolution, FFT, matrix-multiply, elementwise kernels and thread synchronization. Native-writing samples show StemOutputWriter.readSamples, Foundation Data replacement/append paths, memory movement and Swift retain/release. This supports investigating model/output tensor materialization and native byte-packing/allocation behavior. It does not quantify exclusive CPU percentages from inclusive sample counts, prove an allocation leak, or replace an Instruments Allocations/Leaks/physical-footprint/energy study.

Native host memory grows during output writing in this test host. Investigate buffer reuse and autorelease lifetimes in the real detached-task context before asserting an app leak or selecting a fix. Chunked file reads alone do not prove all intermediate objects are promptly released.

## MPS compatibility

Pinned PyTorch **2.5.1** reports MPS built and available. A test-only probe loaded the exact hash-verified HTDemucs checkpoint and identical CPU/split/segment/overlap settings. CPU produced valid output. The MPS variant failed with:

> NotImplementedError: Output channels > 65536 not supported at the MPS device.

Framework CPU fallback was explicitly disabled. No MPS speed or output-quality comparison is possible after this failure. This is a finding for this checkpoint/runtime/path, not a claim that all Demucs/MPS combinations are impossible. Demucs itself also contains explicit CPU spectral transforms/transfers on its MPS path; “MPS available” never meant every operation runs on GPU. A separately identified hybrid fallback experiment or newer pinned runtime can be evaluated later with numerical/quality, memory and packaged-runtime gates. Neither was enabled in the shipping app.

PyTorch background: [MPS backend](https://docs.pytorch.org/docs/stable/notes/mps.html). Installed pinned source and actual test outcomes take precedence over documentation for newer releases.

## Storage fault results

| Check | Observed result |
| --- | --- |
| 100 workspace creation/destruction cycles | Pass: zero jobs remaining |
| Recovery with a live lock | Pass: live workspace preserved |
| Unmarked workspace | Pass: preserved |
| Corrupt raw worker output | Pass: rejected, no destination leftovers |
| Crashed job with accessible staging | Pass: owned workspace/staging removed |
| Destination owner mismatch | Pass: unrelated marker/content preserved |
| Destination deletion denied | **Defect reproduced:** partial output remains; retry record discarded |
| Unresolvable stored bookmark | **Defect reproduced:** partial output remains; retry record discarded |
| Workspace deletion denied, then restored | Workspace remained initially; subsequent recovery removed it |
| Full 64 MB destination image | Pass: refused before preparation with free-space message |
| Full 64 MB temporary image, roomy output destination | **Missing preflight confirmed:** enters conversion then fails with Cocoa error 640 (out of space); working files were cleaned |
| Destination image unmounted during recovery, then remounted | **Defect reproduced:** hidden partial output survived; retry record was lost |

The volume tests used one newly created, disposable HFS+ disk image. It was detached and deleted afterwards. No physical disk was filled or detached. A disk-image reconnect is stronger than only corrupting a bookmark, but does not qualify every physical removable drive, iCloud or network-volume behavior.

The first harness prototype discovered that Foundation ignores TMPDIR for the real workspace root on this host. That initial run was stopped and its one precisely identified synthetic workspace was removed under its ownership lock. Final reported storage/baseline runs use the explicit generated test-root seam. This limitation and source override are recorded, not hidden.

Additional assertions passed:

- Cancellation after the first completed inference chunk: sanitized cancellation, unchanged input, zero output/jobs.
- Cancellation at the worker writing event: same cleanup result.
- Cancellation scheduled 50 ms after the second writing event (native output phase): same cleanup result. This verifies cancellation in that phase; the harness does not claim an exact byte-write interruption point.
- A 1201-second input was rejected before preparation/worker startup, with zero jobs/output.

The test host returns process exit 0 after reporting a handled error; the Python harness asserts the error/result events and filesystem state. Thus exit 0 in fault-case JSON is not a claim that separation succeeded. The final ordinary app temp root was empty. Final temporary generated audio/image/session directories were absent; only small measurement reports, samples and the test binary remain.

## Ordered follow-up implementation plan

1. **Durable cleanup retry.** Change JobWorkspace.swift and its tests. Retain a minimal owner-bound record until deletion succeeds or the stage is confirmed absent. Separate bulky local working-audio disposal from a small pending external-cleanup journal. Retry on later launches/volume availability; preserve live-lock, symlink and marker checks. Never delete completed user output. Gate: denied deletion, corrupt/stale bookmark and actual unmount/remount cases no longer lose recoverable tracking.
2. **Both-volume capacity checks.** Change SeparationSession.swift and supporting domain/infrastructure tests. Budget input + four raw stems on the actual temp volume and staging WAVs on the destination; combine when volume identity matches, include margin, handle unknown capacity explicitly and retain robust ENOSPC cleanup. Gate: both constrained-volume cases fail before allocating large working audio, with accurate sanitized errors.
3. **Cleanup observability and soak.** Emit sanitized phase/error codes for failed cleanup without paths/bookmarks/audio; avoid unbounded file logging. Test multiple jobs in one real app lifetime, force-quit at each preparation/inference/write/rename boundary, startup recovery, sleep/reboot and reconnect. Investigate initialization failure paths. Gate: no accumulating owned bulk data; minimal unresolved journal entries stay bounded, inspectable and retryable.
4. **Memory-focused optimization.** Start with runtime/worker/stem_worker.py full-result normalization/validation/serialization copies and StemOutputWriter.swift data construction/lifetimes. Measure alternatives such as in-place tensor operations where safe and bounded reusable output buffers. Gate: identical shape/format, finite output, reference numerical comparison and representative music listening; lower measured peak without a new cancellation/data-loss regression. Do not replace the model merely to make a memory number look better.
5. **CPU/MPS performance candidates.** Benchmark CPU thread settings under controlled load. Treat MPS/hybrid/newer Torch as separately labelled candidates, not the production default. Preserve the known-working CPU path. Any runtime change requires updated locked artifacts, licences/provenance, native dependency/signing audit and offline bundled proof.
6. **Release qualification.** Complete clean 20-minute, representative music, 8/16 GiB physical-machine testing and real-app Instruments profiles. Re-run storage failures and updater coexistence. Only then choose a new version/build, do local signed installation proof, clean GitHub builds and the normal notarized/stapled/update release sequence. None of those production changes were made during this test task.
