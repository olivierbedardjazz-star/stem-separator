# Private Developer ID runtime proof — September 6, 2026

Status: a successful local feasibility check, **not completion of release slice 377**. The full exact-commit CI and redistribution gates remain open.

The helper was re-frozen from the current spec with its permanent bundle identifier. A separate app copy at build/PrivateSigningProof/Stem Separator.app was used; the normal local app was not overwritten by signing. scripts/sign_stem_runtime.sh signed leaves then helper containers with the existing Developer ID identity. scripts/verify_stem_runtime_signatures.sh verified all 37 native helper binaries, expected Team ID/timestamps, hardened runtime on executables and no unreviewed exceptions. Sparkle nested components were signed separately, the helper file manifest was regenerated after helper signing, and the outer app was sealed last.

Strict/deep signature verification passed before and after real inference. The optimized native diagnostic processed a synthetic 14-second stereo input through the signed helper, reported three completed chunks, and saved four validated 24-bit WAV files. Its controlled missing-destination check also passed. No hardened-runtime/JIT/library-validation exception was needed in this test.

Logs: build/StemRuntime/private-signing-proof.log, private-sparkle-signing.log, private-signed-inference.log. This test does not prove interactive signed-app UI, provisional DMG installation, Gatekeeper, minimum-OS hardware coverage, CI, Apple acceptance or model redistribution permission. No Apple submission or public model-bearing upload occurred.

A shared data-driven DMG settings module now preserves the existing numeric Finder layout while treating paths as data. Its Unicode/apostrophe-path test passes; no DMG has yet been produced from it. Four build-tool unit tests pass in Tests/Release.
