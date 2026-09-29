# Mac App Store release status — 2026-09-28

The existing Developer ID DMG, Sparkle ZIP/appcast, and GitHub direct release remain unchanged. The Store variant shares the same source repository but has its own Xcode scheme, App Sandbox entitlements, installer, build number, and App Store Connect submission.

## Verified build and delivery

- The Store source variant was merged through [PR #1](https://github.com/olivierbedardjazz-star/stem-separator/pull/1); [clean macOS CI](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/36502198221) passed for both targets. The Store Release 0.1.2 archive's ad-hoc-signed local app passed the actual picker → Demucs four-stem/karaoke → Finder workflow, with no retained job audio. This proves the sandboxed workflow on this Mac; an Apple distribution-profile-signed app cannot be launched locally before Store delivery.
- Apple Distribution and Mac Installer Distribution certificates and the exact Store provisioning profile were installed locally in the owner's account. Their private keys and the App Store Connect API private key are outside the repository.
- The first Apple-signed Store package, **0.1.2 (102)**, passed upload validation but Apple processing rejected it with error 91109 because the embedded provisioning profile retained `com.apple.quarantine`. It must not be submitted.
- The Store pipeline now signs the three standalone Torch executables with sandbox entitlements, embeds the provisioned application identifier in the distribution signature, strips/inspects quarantine before signing, and checks altool output rather than trusting its exit code alone. It uses a Store-only build counter in `Packaging/AppStore/release-config.json`, leaving the direct build number untouched.
- **0.1.2 (103)** archived, signed, packaged, and passed local signature/product checks. Apple package validation accepted it. Upload delivery ID: `77ef6fbc-1784-491f-b125-407508d2b744`. Altool reported `BUILD-STATUS: VALID`; App Store Connect still showed the build upload as **Processing** when last inspected. The Store package is `build/AppStoreRelease/0.1.2-103/export/Stem-Separator-App-Store-0.1.2-103.pkg` (release working artifact, not the public direct installer).

## App Store Connect listing

- App Apple ID `6817148877`, bundle ID `com.oliviergrenierbedard.stemseparator`, macOS version `0.1.2`, free price, Music category, 4+ age rating, and worldwide availability are configured.
- Description, keywords, support/marketing/privacy URLs, copyright, review notes, and contact fields are saved. Sign-in required is off. The version has **one accepted Mac screenshot**. No review audio attachment is selected, per the owner's request.
- The App Privacy questionnaire says no data collected, but the declaration is still **draft**. Apple's Publish dialog requires an explicit agreement to the accuracy/compliance statement; do not accept that agreement without confirmation at action time.
- The Digital Services Act section in App Information says account-level setup is missing. The owner must choose the legally correct trader status; do not infer it from the app being free.
- Build 103 must finish App Store Connect processing and be selected for version 0.1.2 before Add for Review. Do not claim review submission or Store publication until those states are observed.

## Resume

1. Refresh TestFlight → macOS Builds. Confirm 0.1.2 (103) leaves Processing and appears as an available build; investigate any processing error before continuing.
2. Select 103 on the version page and complete any build encryption-compliance prompt accurately. Keep one screenshot and no audio attachment.
3. Resolve App Privacy publication and Digital Services Act status with the owner's exact confirmations where Apple requires legal or private-contact declarations. Add for Review, submit, and record the resulting review state.
4. Commit/push the Store pipeline corrections after reviewing their diff and preserving unrelated untracked work. Future Store builds use the next Store-only build number; direct release artifacts remain separate.
