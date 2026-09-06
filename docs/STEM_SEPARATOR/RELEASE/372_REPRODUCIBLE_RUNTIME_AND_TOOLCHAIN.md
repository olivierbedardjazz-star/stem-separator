# Slice 372 — Reproducible runtime and build-tool closure

Status: pending. Depends on: 370. Outcome: a fresh arm64 builder reconstructs the complete offline worker from verified inputs, preserving a signable bundle layout.

## Exact file work

Change `scripts/build_stem_runtime.sh`, `scripts/embed_stem_runtime.sh`, `scripts/audit_stem_runtime.py`, `scripts/create_runtime_manifest.py`, `scripts/verify_packaged_runtime_launch.sh`, `runtime/requirements-lock.txt`, `runtime/StemWorker.spec`, `runtime/collect_notices.py`, `runtime/provenance.json`, `runtime/python-build-metadata.json`, `runtime/test_worker.py`, and `runtime/test_worker_control.py` as required by proof. Create `Packaging/build-tools.lock.json`, `Packaging/packaging-tools.lock`, `scripts/bootstrap_build_tools.sh`, `scripts/bootstrap_packaging_tools.sh`, `Tests/Release/test_runtime_audit.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/runtime-closure.md`.

## Low-level work and data flow

1. Keep current Python/model versions and verified download hashes unless a measured incompatibility requires a documented replacement. Resolve every transitive Python distribution to an artifact hash, including build backends for source distributions. Use hash enforcement and a controlled wheelhouse; record source→wheel provenance where a wheel is built locally. Never label a plain version list a hash lock.
2. Lock Xcode/XcodeGen selection and packaging tools with versions, URLs/checksums as applicable. macOS/Xcode are host prerequisites, not app payload. Bootstrap tools under workspace build directories without changing system Python. Packaging's dmgbuild environment is separate from the worker environment and excluded from the app.
3. Add a true cold mode that uses empty task-owned build/cache directories and verified downloads. Existing mode reuses portable-venv and frozen output; do not call that proof cold. Revalidate cached artifact hashes. Isolate generated legal metadata and compare against checked-in reviewed records; source drift must be reported, not silently committed by CI.
4. Freeze the worker as the current PyInstaller helper app. Preserve `Contents/MacOS`, `Frameworks`, `Resources`, framework Versions/Current links and executable permissions. Read pinned PyInstaller layout/signing guidance before structural changes. Never flatten frameworks or copy with symlink dereferencing. No helper/model resources may resolve outside the app.
5. Extend Mach-O audit: handle supported thin/fat magic/endian variants, identify code without following escaping links, assert the main/worker executables are arm64, and inspect every loaded library for usable arm64. A vendor framework containing extra slices is documented, not silently stripped after signing. Resolve `@loader_path`, `@executable_path`, and `@rpath` in the relevant host context; reject unresolved loads and external non-system paths. Normalize version tuples before checking macOS 14 compatibility. Include missing symlink target, unknown binary format and duplicate code alias checks.
6. Inventory the actual collected libraries and compare to rights records. Remove unnecessary payload only after demonstrating no import/runtime regression. No ffmpeg/downloader runtime is reintroduced. Generate pre-sign file/symlink manifests and retain a separate post-sign manifest contract for 377.
7. Expand the worker test beyond a two-second tone: multiple real chunks, finite four-channel-group outputs, correct byte lengths, empty HOME, minimal PATH, disabled network, missing/tampered model, cancellation and parent death. Drain stdout/stderr concurrently in the harness and enforce bounded subprocess timeouts. Test from a relocated path containing spaces/Unicode, with no dependency on cwd.

## UI/data behavior

Input/output, model settings and progress remain unchanged. Tests use synthetic rights-cleared fixtures; user music is never placed in CI. Preparation and writing remain separate stages from real completed-chunk progress. The test driver may use build Python, but the launched helper must not import from it; record its sanitized environment and loaded paths.

## Dependency/licence implications

Hash locks and build tools add no user-installed prerequisites. Account for source-built wheels and embedded native-library licences. If a rights-driven model change becomes necessary, it is a new product-validation change, not a quiet packaging substitution.

## Tests and packaging impact

Cold reconstruction, hash mismatch rejection, unsupported architecture/OS, broken relative loads/symlinks, forbidden developer paths and missing notices must have meaningful fixture tests. Record worker/model hashes, payload size, Mach-O inventory and a successful offline inference. Verify deterministic inventories rather than promise bit-identical signed binaries across machines.

## Stop conditions

Unhashed input, warm-cache-only success, external runtime dependency, unsupported deployment floor, malformed framework, missing notice, or model mismatch. No downstream signed candidate from an unverified runtime.
