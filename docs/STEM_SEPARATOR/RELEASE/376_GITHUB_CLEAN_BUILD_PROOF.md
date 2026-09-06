# Slice 376 — Exact-commit GitHub clean build

Status: pending. Depends on: 375 for remote execution; author before first push. Outcome: independently reproducible source-to-working-app evidence on native arm64 GitHub-hosted hardware, without local signing credentials.

## Exact file work

Create/change `.github/workflows/clean-build.yml`. Create `scripts/ci_clean_build.sh`, `scripts/verify_source_membership.py`, `Tests/Release/test_source_membership.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/github-clean-build.md`. Change `scripts/run_clean_packaged_runtime_proof.sh`, `scripts/bootstrap_build_tools.sh`, `scripts/build_stem_runtime.sh`, and test-runner configuration in `project.yml` only as required by the actual runner environment. No release/publish workflow in v1.

## Workflow and data flow

- Trigger on pull request, main push and workflow_dispatch; least privilege `contents: read`, immutable action revision pins, bounded timeout and per-ref concurrency. Do not use `pull_request_target` to execute PR code. No secret values, certificate import or local self-hosted runner.
- Initial runner choice: explicit `macos-15` arm64, with an additional `macos-14` floor lane where current availability/toolchain permits. Verify `uname -m`, selected Xcode/SDK, host OS and free space at runtime. GitHub labels/images evolve; adjust based on current official runner documentation and record the exact image. A hosted minimum-OS test does not replace interactive hardware proof.
- Start from the workflow's exact checked-out SHA and clean tree. Use 372 cold bootstrap, no carried venv/frozen helper/model cache on the mandatory cold run. Fetch source/model only under their reviewed terms, verify hashes, reconstruct worker, regenerate project and compare committed/generated configuration. Do not quietly commit generated drift.
- Build Debug/test and optimized Release using declared Xcode. Verify excluded downloader files are absent from compile/resource membership. Run deterministic native/service/protocol/error tests, multi-chunk helper inference, cancellation/parent death, notices, Mach-O closure and moved-app tests. App UI tests require an actual usable runner GUI session; if unavailable, record that limitation and keep their local installation gate mandatory.
- Run the worker with minimal PATH and a task-owned empty HOME, network denied during inference; run it from the built .app and relocate the bundle outside build products. Build tools may exist on the runner, so loaded-path audit plus environment isolation are required—not “the runner had no Python.” Native decoding/output assertions exercise the app code too.
- Retain sanitized xcresult summaries, source/config/dependency manifests, tool versions and runtime outcomes. Do not upload model-bearing `.app` artifacts unless 370 permits that distribution. Do not create GitHub Releases from CI. Prefer evidence-only artifacts for the initial workflow.
- Capture run URL, exact head SHA, job outcomes and cold-cache evidence. Local release preflight compares this SHA and input/config hashes to the candidate. Matching source is not a byte-for-byte reproducibility claim across different SDK/signing environments; record toolchain differences and reprove locally with selected release tools.

## UI/dependencies/licences

No UI change. Automation uses generated fixtures only. Hash-lock build tools/actions, avoid nightly implicit upgrades, and enforce model access/distribution policy. No manually added repository secrets are required.

## Tests / packaging impact

Include a deliberate missing-runtime/tampered-input negative test to prove checks fail, and test source membership with an excluded-file fixture. Confirm cold run succeeds after source export with no local file dependencies. Observe RAM/disk limits and bound fixture duration instead of blindly allocating full 20-minute tensors on a small runner. Main-branch candidate proof must succeed, not merely a different PR merge revision.

## Stop conditions

Wrong architecture, uncommitted inputs, missing upstream access, hash drift, insufficient resources without a valid test result, unresolved tests, or a different source SHA. A GitHub VM build is never labeled as “installed on a new user's Mac.”
