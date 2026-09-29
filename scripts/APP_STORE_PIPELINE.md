# Mac App Store release command

This path is separate from `scripts/RELEASE_PIPELINE.md`. The repository, `project.yml` marketing version, app resources, and bundled Demucs runtime are shared. The Store build number is in `Packaging/AppStore/release-config.json` and overrides the direct build number during Store archive creation. The App Store product is a sandboxed macOS `.pkg`; the direct product remains a Developer ID notarized DMG and Sparkle ZIP. Never overwrite an existing released artifact. Increment the Store build number after any upload that Apple processes or rejects.

## Current implementation

`scripts/app_store_release.py` has explicit, fail-closed commands. It never creates an App Store Connect app record, uploads without the `upload` command, or submits for App Review. The first Store submission still needs a real sandbox workflow proof, Apple Distribution credentials/provisioning, a signed package, completed metadata, and Apple processing. The local `sign-local` option is for sandbox testing only and cannot produce a distributable package.

Prerequisites: current Xcode, XcodeGen (`build/BuildTools/xcodegen/bin/xcodegen` or on `PATH`), the frozen worker from `scripts/build_stem_runtime.sh`, the pinned sandbox-compatible OpenMP library from `scripts/build_store_libomp.sh`, and the `StemSeparatorAppStore` target/scheme. The OpenMP source archive is verified by SHA-256 and rebuilt for arm64/macOS 15.1; it replaces only the Store helper's `libomp.dylib`. Store app and worker entitlements live at `Packaging/AppStore/StemSeparator.entitlements` and `Packaging/AppStore/StemWorker.entitlements`.

Run in order from the repository root:

```sh
scripts/build_stem_runtime.sh
scripts/build_store_libomp.sh
python3 scripts/app_store_release.py preflight
python3 scripts/app_store_release.py archive
python3 scripts/app_store_release.py verify-archive
python3 scripts/app_store_release.py sign-local
python3 scripts/app_store_release.py verify-local
```

The unsigned archive is `build/AppStoreRelease/<version>-<build>/StemSeparator.xcarchive`. The local test app is under `signed-local/Stem Separator.app`. Test import, four stems, karaoke, output folder, cancellation, cleanup, and relaunch with this actual signed app. `preflight` checks source/tool/runtime presence; it does not claim certificate availability or App Store acceptance.

For an App Store package, provision the **same app bundle ID** in Apple's developer account, install a valid **Apple Distribution** code signing identity and a **Mac Installer Distribution** identity, and keep the app's Mac App Store provisioning profile outside this repository. Apple currently calls the installer identity `3rd Party Mac Developer Installer: ...` in its packaging documentation. The exact names installed on this Mac must be supplied as environment variables:

```sh
export MAS_APP_SIGN_IDENTITY='Apple Distribution: Team Name (TEAMID)'
export MAS_INSTALLER_SIGN_IDENTITY='3rd Party Mac Developer Installer: Team Name (TEAMID)'
export MAS_PROVISION_PROFILE='/absolute/private/path/profile.provisionprofile'
python3 scripts/app_store_release.py sign
python3 scripts/app_store_release.py verify-signed
python3 scripts/app_store_release.py export
```

The `sign` phase copies the unsigned archive with `ditto`, embeds the supplied profile, removes inherited quarantine attributes, signs each standalone executable with sandbox inheritance, signs other Mach-O leaves and nested bundles from inside out, signs StemWorker with sandbox inheritance, then signs the main app with its sandbox, file access, and provisioned application-identifier entitlements. It checks the Team ID, executable entitlements, and signatures. `export` runs Apple's `productbuild` using the Store installer identity and creates one signed `.pkg` under `build/AppStoreRelease/<version>-<build>/export/`. Existing signed outputs are never silently replaced. A code-signing pass alone does not establish App Review acceptance or sandbox functionality. The App Store distribution profile cannot be used to launch this final signed app locally; use the ad-hoc `sign-local` build for local UI proof, then Apple's package validation and TestFlight/Store processing for distribution proof.

Use an App Store Connect API key kept in an owner-only `.p8` file **outside the repository**. Do not paste its contents into chat or commit it. These variables name the key; the script rejects partial credentials and group/world-readable key files:

```sh
export ASC_KEY_ID='KEY_ID'
export ASC_ISSUER_ID='ISSUER_UUID'
export ASC_P8_PATH='/absolute/private/path/AuthKey_KEY_ID.p8'
python3 scripts/app_store_release.py validate
python3 scripts/app_store_release.py upload
python3 scripts/app_store_release.py status
```

`validate` asks Apple's `altool` to validate the exact exported package and checks its text for a positive success marker because altool can exit 0 on validation errors. `upload` requires the same positive confirmation and records Apple's delivery UUID in the ignored `delivery.json` beside the archive. `status` uses that UUID and one normal-text build-status request; it does not wait indefinitely or mistake a `FAILED` response for success. If a package is rejected during processing, fix the cause, increment the Store build number, create a new archive, and upload that new package. After Apple processing, associate the build with the version, complete metadata/privacy/review information, and submit for review with the App Store Connect API where supported, or do those account-specific steps in App Store Connect. An API key with Developer role can upload but may not have permission to submit for review.

Apple now documents a **direct App Store Connect REST API binary upload** as an alternative to Xcode, `altool`, and Transporter. This script uses `altool` for the exact exported `.pkg` because that path is also supported and avoids building an unverified custom binary-upload client. No GitHub release DMG/ZIP is generated by this command.

Sources: [Apple packaging and Store package signing](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution), [distribution signing](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/), [sandboxed helper tools](https://developer.apple.com/documentation/xcode/embedding-a-helper-tool-in-a-sandboxed-app), [upload builds and current API options](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds).
