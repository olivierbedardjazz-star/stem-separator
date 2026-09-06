# Slice 375 — One public repository and reviewed source

Status: pending. Depends on: 370, 374. Author the 376 workflow before the first push. Outcome: a deliberate public source tree with a matching remote, no secrets and no accidental binary publication.

## Exact file work

Change `.gitignore`. Create `README.md`, `LICENSE.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/workflows/clean-build.yml` (specified in 376), and `docs/STEM_SEPARATOR/RELEASE/evidence/repository-setup.md`. Use `scripts/audit_public_source.py` from 370. Sanitize selected public docs if needed, recording their exact paths before changes. Git metadata and remote are created during execution, not this plan.

## Implementation steps

1. Check the GitHub slug still available and account identity; if an existing matching repo appears, inspect ownership/content before reuse. Use the single public `olivierbedardjazz-star/stem-separator` repository and default branch main. No second update repo, Pages dependency, custom domain or Actions signing secrets.
2. Expand ignores for `.venv-packaging`, other local virtualenvs, `release-evidence/`, local release config/credentials, private keys/cert exports, test results, downloaded models, runtime caches and incidental screenshots/audio. A .gitignore is not a security review. Inspect the exact staged tree and rerun the source audit before first commit/push.
3. Build a required source/resource allowlist from project.yml, runtime spec, scripts and docs. Excluded downloader source under `TemplateApp/Download`, `Runtime`, `RuntimeDependencies`, obsolete UI files and `archive/` remain local reference material unless explicitly reviewed as necessary public source; never compile or upload them by accident. Ensure excluding them does not cause XcodeGen missing-input failures. Do not delete unrelated local history/assets merely to publish.
4. Keep reviewed brand assets, required licence texts, synthetic test fixture and build input metadata. Remove local absolute paths/user examples from public diagnostics where not needed. Existing historical docs must not leak credential snippets or personal workflow material. All build requirements must be present in the public source or fetched from declared accessible inputs.
5. Preserve project copyright and existing third-party licences. Default LICENSE.md explains owned source is publicly viewable with no new blanket reuse grant; third-party licences continue to apply, brand assets remain separately owned. Do not apply an MIT header to copied code/artwork/model. If an open-source licence is later requested, treat that as a separate owner decision rather than silently granting it here.
6. README explains arm64/native/offline/free scope, installation through final Releases DMG, and source build prerequisites. Before a verified release exists, say downloads are not available yet; do not link a provisional artifact. Security/bug templates ask for app/OS version and sanitized error code, not music/private paths or public credentials.
7. Initialize Git, stage only reviewed paths, verify diff and file-size limits, commit, then create/push to the verified public origin. Record exact SHA and repository URL. Public repository creation does not publish an installer and cannot count as clean CI proof.

## Data flow / dependencies / testing

Public source → reproducible workflow; generated unsigned CI artifacts never automatically enter Releases. Runtime/model binaries stay out of Git history. Reproduce build input resolution from an exported clean source tree before uploading. Licence gates apply separately to source files and downloadable binary payloads. No new app dependency or UI change.

## Stop conditions

Wrong owner/slug, secret/personal content in staged files, unreviewed legacy material, required files excluded, source assets without known publication rights, or misleading installer availability. Fix independently where possible; do not ask the owner to do routine Git setup.
