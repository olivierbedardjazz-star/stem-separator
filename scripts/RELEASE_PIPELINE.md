# Stem Separator release pipeline

All distribution work runs on the owner's Mac. GitHub Actions provides independent clean build/runtime/test proof with no signing keys. Use one public repository for source and Release assets.

1. Run `scripts/build_local_release_app.sh`, local Release/Debug unit tests and UI workflow tests. Review dependency notices and model provenance.
2. Review and commit the exact source locally. No push is needed yet.
3. Run `scripts/archive_release_app.sh`, then `scripts/export_release_app.sh` (nested signing, helper manifest, outer signing, actual bundled inference).
4. Run `scripts/bootstrap_packaging_tools.sh`, `scripts/prepare_provisional_release_dmg.sh`, and `build/StemRuntime/portable-venv/bin/python scripts/release_pipeline.py install-proof`. Complete the signed app UI workflow on this Mac. The automated install proof copies from the mounted DMG to an isolated installation directory; it does not claim a Finder drag or second physical Mac.
5. Publish reviewed source, run the `Clean macOS build` workflow, and record its run ID as `{"id": NUMBER}` in `release-evidence/<version>-<build>/ci-proof.json`. The pipeline independently queries GitHub and requires successful exact-source CI before Apple submission.
6. Run `scripts/submit_notarization.sh`. It submits once and records the ID; repeat to read status. It does not block indefinitely. Only Apple `Accepted` creates the artifact-bound acceptance record.
7. Run `scripts/staple_exported_app.sh`, then `scripts/prepare_release_dmg.sh` and `scripts/notarize_release_dmg.sh`. After Accepted run `build/StemRuntime/portable-venv/bin/python scripts/release_pipeline.py staple-dmg`.
8. Run `scripts/prepare_sparkle_release.sh`, inspect final assets, and `scripts/publish_github_release.sh`. Publication never rebuilds assets or overwrites an existing release. Exact assets are uploaded to a draft, then promoted and downloaded anonymously for hash verification.
9. Run `Verify published installer` with the immutable release tag on both hosted macOS versions, and test a real A-to-B Sparkle installation. B repeats all affected gates with a new build/version and becomes the recommended release. Preserve the previous installer for update proof.

Canonical configuration: `Packaging/release-config.json`. Version/build authority: `project.yml`. Records and artifacts: ignored `release-evidence/<version>-<build>/`. Legacy timestamp stamps cannot authorize a handoff. Changed source requires renewed proofs; never change an already published artifact's bytes.

Private keys remain in the local Keychain. No model download or system Python is required on an end user's Mac. No signing/notarization approval is inferred from an unsigned build or a standalone helper test.

The pinned Sparkle generator signs both ZIP and feed. `verify_sparkle_signatures.swift` verifies both signatures with the public key embedded in the app; it never accesses private signing material. The stable latest feed must match the uploaded signed bytes.

Read-only handoff status: `build/StemRuntime/portable-venv/bin/python scripts/release_status.py release-evidence/<version>-<build> --complete`. Final completion requires downloaded-installer and real update evidence as well as notarized assets. Full records remain local; publish sanitized summaries only.
