# Local execution proof — September 6, 2026

After the owner allowed the pending Desktop-folder prompt, the complete app-hosted StemSeparatorTests suite passed in optimized Release: 15 tests, zero failures. Log: build/StemRuntime/release-tests-after-permission.log.

Coverage includes real bundled inference, a 14-second multi-chunk native conversion/separation/WAV output test, cancellation, source-reference clearing, output-picker cancellation, failure stage/path-redaction assertions, transactional output/collisions, intake formats, recovery ownership, settings isolation and invalid updater configuration rejection.

Test harness: local ad-hoc signature, ENABLE_HARDENED_RUNTIME=NO and ENABLE_TESTABILITY=YES for test injection. These accommodations do not change the project's production Release hardened-runtime setting and are not Developer ID proof. UI/install/Gatekeeper/update-transition proofs remain pending.

Sparkle reported the expected HTTP 404 for the configured but unpublished feed. No successful no-update/feed/publication result is claimed.
