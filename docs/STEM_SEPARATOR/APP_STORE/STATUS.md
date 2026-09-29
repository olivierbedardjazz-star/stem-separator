# Mac App Store release status — 2026-09-28

The existing Developer ID DMG, Sparkle ZIP/appcast, and GitHub direct release remain unchanged. The Store variant shares the same source repository but has its own Xcode scheme, App Sandbox entitlements, installer, build number, and App Store Connect submission.

## Verified build and delivery

- The Store source variant was merged through [PR #1](https://github.com/olivierbedardjazz-star/stem-separator/pull/1); the final source push's [clean macOS 15 and 26 CI](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/36512654783) passed for both targets. The Store Release 0.1.2 archive's ad-hoc-signed local app passed the actual picker → Demucs four-stem/karaoke → Finder workflow, with no retained job audio. This proves the sandboxed workflow on this Mac; an Apple distribution-profile-signed app cannot be launched locally before Store delivery.
- Apple Distribution and Mac Installer Distribution certificates and the exact Store provisioning profile were installed locally in the owner's account. Their private keys and the App Store Connect API private key are outside the repository.
- The first Apple-signed Store package, **0.1.2 (102)**, passed upload validation but Apple processing rejected it with error 91109 because the embedded provisioning profile retained `com.apple.quarantine`. It must not be submitted.
- The Store pipeline now signs the three standalone Torch executables with sandbox entitlements, embeds the provisioned application identifier in the distribution signature, strips/inspects quarantine before signing, and checks altool output rather than trusting its exit code alone. It uses a Store-only build counter in `Packaging/AppStore/release-config.json`, leaving the direct build number untouched.
- **0.1.2 (103)** archived, signed, packaged, and passed local signature/product checks. Apple package validation accepted it. Upload delivery ID: `77ef6fbc-1784-491f-b125-407508d2b744`. Altool reported `BUILD-STATUS: VALID`; App Store Connect now shows its upload **Complete** and build 103 available. It is selected and saved for Store version 0.1.2. The package is `build/AppStoreRelease/0.1.2-103/export/Stem-Separator-App-Store-0.1.2-103.pkg` (release working artifact, not the public direct installer).

## App Store Connect listing

- App Apple ID `6817148877`, bundle ID `com.oliviergrenierbedard.stemseparator`, macOS version `0.1.2`, free price, Music category, 4+ age rating, and worldwide availability are configured.
- Description, keywords, support/marketing/privacy URLs, copyright, review notes, and contact fields are saved. Sign-in required is off. The version has **one accepted Mac screenshot**. No review audio attachment is selected, per the owner's request. Build 103's export-compliance answer is saved as none of Apple's listed encryption algorithms, consistent with the inspected Store app and worker; the Missing Compliance warning cleared.
- With the owner's explicit confirmation, the **no data collected** App Privacy declaration was published; App Store Connect confirmed publication by Olivier Grenier Bedard. The owner identified as a **non-trader** under the EU Digital Services Act. App Store Connect shows DSA compliance **Active** and all current regulatory requirements completed.
- With the owner's permission, the saved private review-contact phone was used for submission. The version's one screenshot and no audio attachment were retained. The selected item was submitted to Apple App Review on **Sep 28, 2026 at 11:14 PM** local time: submission ID `5215e42c-6aa5-4867-b3bb-47642385a5d2`. App Store Connect confirmed **Waiting for Review** for macOS 0.1.2 (103). This is not approval or public Store availability.

## After Apple reviews

1. Check the App Review submission status. If Apple requests changes, address the cited issue, increment the Store-only build number, archive/test/sign/upload a new Store build, and resubmit. Do not replace the direct release artifacts.
2. If Apple approves the version, verify the live listing and install it through the Mac App Store on an eligible Apple Silicon Mac. The version is configured to release automatically after approval; approval is not itself installation proof.
3. For a future Store update, increment the Store-only build number. The direct release artifacts and notarization remain separate; do not overwrite them.
