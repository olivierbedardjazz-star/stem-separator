# Bundled stem worker

For private local evaluation only. Model redistribution clearance is unresolved.

From an Apple Silicon Mac with Xcode and XcodeGen as build tools, run:

```
scripts/build_local_release_app.sh
```

Build tooling downloads the pinned standalone Python distribution, installs runtime/requirements-lock.txt, verifies the checkpoint hash, freezes the helper, audits binary deployment floors and external dependencies, and embeds it in the native Release app. Users of the resulting bundle do not need any of those build tools or an internet connection.

The helper is located at Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker. Models and libraries belong to that nested app; never modify them after final signing. The app only sends a private interleaved 44.1 kHz stereo float32 input, never a user-selected model or Python command. Results are validated and encoded as 24-bit WAV by Swift.

Validation commands:

```
scripts/verify_packaged_runtime_launch.sh
build/StemRuntime/portable-venv/bin/python runtime/test_worker_control.py build/StemRuntime/dist/StemWorker.app/Contents/MacOS/StemWorker
```

The packaged proof explicitly denies network access with macOS sandbox-exec, gives the worker an empty HOME and minimal PATH, and runs real inference. It is not a GitHub runner, Gatekeeper, hardened runtime, or notarization proof.

Local GUI test harness command (ad-hoc, no Apple identity):

```
xcodebuild test -project TemplateApp.xcodeproj -scheme TemplateApp -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath build/ReleaseTests/DerivedData CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- ENABLE_HARDENED_RUNTIME=NO ENABLE_TESTABILITY=YES
```

The local harness disables hardened runtime because its ad-hoc identity does not match the vendor-signed Sparkle framework. This is a command-line test override; project.yml retains hardened runtime for Release. Actual shipping must sign every nested component with the selected Developer ID, then prove the hardened build. Do not solve that release step by carrying this test override into distribution.

Full license texts are in docs/LEGAL/RuntimeLicenses. Dependency inventory and Python/model provenance are checked in; downloaded artifacts and generated builds are ignored. The Python component license texts come from the matching hash-verified full standalone archive, whose metadata is in python-build-metadata.json. No GitHub push or CI execution was performed in this local implementation pass.
