# Slice 370 — Rights, baseline and public-source boundary

Status: pending. Depends on: none. Outcome: a measured starting point and explicit permission/compliance record for every material that would become public. Source visibility and model-binary distribution are assessed separately.

## Exact file work

Create `docs/STEM_SEPARATOR/RELEASE/evidence/baseline.md`, `docs/STEM_SEPARATOR/RELEASE/evidence/rights-matrix.md`, `docs/STEM_SEPARATOR/RELEASE/evidence/public-source-review.md`, `scripts/audit_public_source.py`, and `Tests/Release/test_public_source_audit.py`. Change `runtime/provenance.json`, `runtime/dependency-inventory.json`, `runtime/collect_notices.py`, `docs/LEGAL/THIRD_PARTY_NOTICES.md`, and relevant `docs/LEGAL/RuntimeLicenses/` entries only when supported by evidence. No model replacement in this slice. Licence-policy files for owned source are finalized in 375.

## Low-level work and data flow

1. Capture source-tree digest before Git exists, active build identity, current app/UI screenshots, logo/icon and banner hashes, and exact shared primitive hashes. Record the owner-confirmed successful separation and the earlier unexplained generic error as separate observations. Do not imply the diagnostic improvement repaired a demonstrated root cause.
2. Enumerate what actually ships from the PyInstaller TOC, Mach-O inventory and app resource manifest. Distinguish imported runtime, collected but unused payload, build-only packages, model, artwork, fonts and template-owned source. Installed pip metadata alone is not the shipping inventory.
3. For each entry record component/version, source and immutable revision or artifact hash, governing licence text, attribution/source obligations, shipped paths, evidence URL/date, and disposition. Review Torch's collected native libraries, Python's embedded third-party code, PyInstaller bootloader exception and any collected LGPL components such as lameenc if present. Prefer excluding genuinely unused payload via a measured spec change in 372 rather than claiming it is absent.
4. Investigate the selected `955717e8-8726e21a.th` checkpoint specifically. Compare upstream release/README/terms and the maintainer's May 2022 statement with the checkpoint's provenance. Preserve the unresolved status until evidence supports a conclusion; MIT code alone is insufficient. Do not contact maintainers without explicit messaging authorization. If evidence cannot settle redistribution, block public model-bearing artifacts and report options; do not quietly ship another model.
5. Review the prospective public source list rather than recursively uploading the workspace. Flag credentials/private keys, local evidence, user music/screenshots, personal operational notes, binary caches, and copied legacy code not needed to build Stem Separator. Scan filenames and contents without echoing suspected secret values. Record sanitized paths/categories only. Review reference artwork/fonts for publication as source assets as well as bundled use.
6. Teach notice generation to consume an explicit reviewed rights record, not permanently overwrite production notices with evaluation-only prose. Fail release checks when a shipped component has no disposition/required notice. A model or dependency change invalidates corresponding rights and runtime evidence.

## UI and architecture impact

No UI or model behavior changes. Preserve Terms/Privacy modal mechanics. User-visible legal text is updated in 371 only after findings; no blanket licence promise or claim of Apple approval is inserted.

## Dependency/licence implications

No new app dependency. Audit tooling is build-only. Retain third-party copyright/licence files verbatim where required. Do not infer that public hosting automatically means MIT/open-source licensing of owned code or brand assets.

## Tests, packaging and evidence

Test scan fixtures containing dummy secret patterns, ignored build material, allowed public key and normal source; verify reports do not repeat dummy secret contents. Reconcile every shipped component to its rights entry. Verify collected notices are deterministic and cannot revert approved metadata. Store the exact checkpoint hash and evidence conclusion. Public CI retention of model-bearing build artifacts is a distribution decision too.

## Stop conditions

Stop affected publication for unresolved redistribution rights, unknown asset ownership, missing required source/notices, or a detected credential/personal-data leak. Other local engineering may continue. Completion requires documented dispositions, not simply an inventory of package names.
