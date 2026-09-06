# Identity and key setup — partial implementation

September 6, 2026. Permanent main ID is now `com.oliviergrenierbedard.stemseparator`, planned helper spec ID `com.oliviergrenierbedard.stemseparator.worker`; the frozen helper must still be rebuilt from that spec. Project version is 0.1.0/build 100. XcodeGen regeneration completed.

The app-specific Sparkle account `stem-separator-ed25519` was bootstrapped in the local Keychain; only its public key was written to project.yml/generated project. ensure_sparkle_keys.sh verified agreement. No private key export or repository secret was created. Sparkle tool lookup now uses an explicit local DerivedData location rather than selecting from global unrelated builds.

The future single public repo/feed is configured as olivierbedardjazz-star/stem-separator. No repository or feed has been published. Legal update/privacy wording now reflects configured-but-not-yet-published updates and stage/error-code diagnostics while retaining evaluation-only status. Update configuration rejects invalid Ed25519 key length and credential/query-bearing URLs.

Release build succeeded: build/StemRuntime/release-configuration-build.log. Targeted tests are recorded separately once completed. Signing/notarization/CI/installed-updater proof remain pending. This is not a public-release clearance.

The current targeted XCTest invocation is waiting before test execution. A process sample shows dyld blocked opening a dependent image; the macOS TCC log at 15:29:14 records AUTHREQ_PROMPTING for kTCCServiceSystemPolicyDesktopFolder for the new permanent app ID. This is an observed native permission prompt, not an inferred test failure. The owner has been asked to allow Desktop-folder access. No privacy database or OS protection was modified to bypass it.
