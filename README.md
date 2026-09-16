# Stem Separator

A free native macOS app that separates one audio file into vocals, drums, bass and other instruments (🎁 Surprise). Processing runs offline on your Mac. Python, Demucs and the four-stem HTDemucs model are bundled.

Version 0.1.2 uses MPS model inference and requires Apple Silicon with macOS 15.1 or later. Internal 7.8-second chunking is retained; Demucs spectral transforms explicitly use CPU. Inputs: WAV, AIFF, MP3 and unprotected M4A, mono or stereo, up to 20 minutes. Outputs: four 24-bit stereo WAV files at 44.1 kHz in a new folder, or one Karaoke WAV directly in your chosen destination. Your original audio remains unchanged.

Drop or choose audio, click **Separate Stems** or **Create Karaoke**, choose where to save, and reveal the result in Finder. Use audio you have permission to process.

## Release status

Current release: **0.1.2 / build 102**, signed, notarized and verified through a real Sparkle update. The older 0.1.1 CPU release remains available for macOS 14. [Verified release evidence](docs/STEM_SEPARATOR/RELEASE/evidence/release-0.1.2-acceptance.md).

[Download the latest signed and notarized installer](https://github.com/olivierbedardjazz-star/stem-separator/releases/latest). Open the DMG and drag Stem Separator to Applications. The ZIP and signed appcast serve the built-in Sparkle updater; you do not need to download them.

[Release checks and remaining coverage](docs/STEM_SEPARATOR/RELEASE/RELEASE_CHECKLIST.md) include clean macOS builds, public installer verification, Apple acceptance and a real two-version update.

## Build

Use an Apple Silicon Mac with Xcode. The local reference toolchain is Xcode 26.3; build tools and runtime downloads are pinned in `Packaging/build-tools.lock.json` and `runtime/artifacts-lock.json`.

```sh
scripts/build_local_release_app.sh
```

Internet access is required on the build machine to obtain verified dependencies. It is not needed for end-user separation. Build outputs, models and private signing records are excluded from Git.

Release instructions: [release pipeline](scripts/RELEASE_PIPELINE.md). No Apple signing credentials belong in GitHub Actions. Clean hosted builds run without signing secrets.

## Privacy and licences

No account, payment, audio upload or analytics. Update checks contact GitHub; banner/social links open external services. See [Privacy](docs/LEGAL/TEMPLATE_APP_PRIVACY.md), [Terms](docs/LEGAL/TEMPLATE_APP_TERMS.md), and [Third-Party Notices](docs/LEGAL/THIRD_PARTY_NOTICES.md).

Demucs and the selected HTDemucs checkpoint are attributed under MIT, with the model's historical declaration linked in the notices. Other bundled components retain their own terms. App source/artwork ownership is described in [LICENSE](LICENSE).

Support: info.mymusicalbrain@gmail.com. Please do not post private audio or sensitive diagnostic data in public issues.
