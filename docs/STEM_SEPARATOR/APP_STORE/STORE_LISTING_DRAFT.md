# Stem Separator — Mac App Store listing draft

Status: draft for the separate Mac App Store variant, checked against repository source and Apple's published App Store Connect help on 2026-09-28. Nothing in this file represents a submitted listing or an approved binary. Use only after the sandboxed Store build has passed the full audio workflow.

## Product facts to preserve

- Native macOS SwiftUI app; bundle ID `com.oliviergrenierbedard.stemseparator`; category `Music` (`public.app-category.music` in `TemplateApp/Info.plist`). Apple Silicon only, macOS 15.1 or newer.
- Free, single-file workflow. Accepts WAV, AIFF, MP3, and unprotected M4A, up to 20 minutes. The user chooses the input and destination; the original audio remains unchanged.
- **Separate Stems** exports vocals, drums, bass, and other as stereo 44.1 kHz, 24-bit WAV files in a named folder. The UI labels the fourth stem `🎁 Surprise`; its actual file/protocol name remains `other`.
- **Create Karaoke** exports one stereo 44.1 kHz, 24-bit WAV file made from drums, bass, and other. Vocal remnants or other separation artifacts may remain. Do not claim perfect vocal removal.
- Processing uses a bundled Demucs model/runtime on the Mac. No account, payment, audio upload, app analytics, or runtime/model download is required. The optional banner/social links open external sites in the user's browser. The direct build uses Sparkle; the Store build must use App Store updates.
- Owner/contact shown in existing legal documents: Olivier Grenier Bedard, `info.mymusicalbrain@gmail.com`. Social destinations and Tone Transcribe banner are intentionally retained.

Source checks: `README.md`; `project.yml`; `TemplateApp/Info.plist`; `TemplateApp/Separation/Infrastructure/AudioPreparationService.swift`; `TemplateApp/Separation/Domain/SeparationJob.swift`; `TemplateApp/Separation/Infrastructure/StemOutputWriter.swift`; `TemplateApp/UI/Separation/{AudioInputPanelView,StemOutputPanelView}.swift`; `TemplateApp/UI/Components/AppFooterSocialLinksView.swift`.

## Draft listing fields (English)

| Field | Draft / decision |
| --- | --- |
| App name | **Stem Separator** (14 characters; Apple's limit is 30). Verify name availability in App Store Connect. |
| Subtitle | **Stems and karaoke on your Mac** (29 characters; limit 30). Owner may change before submission. |
| Bundle ID | `com.oliviergrenierbedard.stemseparator`; must match the Store app record and signed build. |
| Primary category | Music. No secondary category proposed. |
| Price | Free. No In-App Purchases or subscriptions. Set Free pricing and intended storefront availability in App Store Connect. |
| Primary language | English (draft; choose exact English locale when creating record). |
| Keywords | `vocals,drums,bass,karaoke,audio,music,separation,wav` (under 100 UTF-8 bytes; do not repeat app name, company, or competitors). |
| Promotional text | Optional; omit for first submission unless needed. |
| Copyright | `2026 Olivier Grenier-Bedard` (confirm the exact legal holder; Apple adds the copyright symbol). |
| Privacy Policy URL | **TBD:** publish a Store-accurate policy at a stable HTTPS URL, then verify it anonymously before entry. Do not point the Store listing at the current direct-build policy, which describes Sparkle update checks. |
| Support URL | **TBD:** publish a stable HTTPS support page containing at least the support email and useful contact guidance; verify anonymous access. Existing README includes `info.mymusicalbrain@gmail.com`, but a dedicated support page is clearer. |
| Marketing URL | Optional; public repository or a dedicated product page, if its claims accurately describe the Store variant. |
| Version | Use the actual Store build's `CFBundleShortVersionString`; never reuse an already uploaded bundle ID/version/build combination. First Store listing's “What's New” field is unavailable; add change notes for later versions. |
| Age rating | Complete Apple's current questionnaire truthfully. Do not guess a numerical rating. The app does not embed a social feed or broad web browser; opening optional external links alone should be classified according to Apple's actual questionnaire wording. |
| Content rights | Owner confirms rights for app artwork, code, bundled dependencies/model, and any sample audio/screenshots. The existing historical model-license assessment is recorded in `docs/STEM_SEPARATOR/RELEASE/evidence/model-owner-assessment.md`. User-provided songs are not bundled. |

### Proposed description

> Stem Separator turns one audio file into four useful tracks on your Mac: vocals, drums, bass, and other. You can also create a single karaoke track without exporting separate stems.
>
> Drop a song into the app or choose a file, select Separate Stems or Create Karaoke, then choose where the result should go. Find the finished WAV files in Finder. Your original recording stays where it is.
>
> Works with WAV, AIFF, MP3, and unprotected M4A files up to 20 minutes long. Processing runs locally with a bundled model. No account or model download is needed.
>
> Separation can leave audible artifacts or some vocal sound in the karaoke track. Use audio you own or have permission to process.
>
> Requires an Apple Silicon Mac running macOS 15.1 or later.

Check this text against the **actual sandboxed Store binary** before upload. The description must remain plain text and under Apple's 4,000-character limit. Avoid claims of perfect isolation, support for protected audio, cloud processing, or unlimited length.

## Screenshot and asset plan

Apple requires **1–10 actual Mac screenshots** in PNG/JPEG. Current accepted Mac dimensions are **1280×800, 1440×900, 2560×1600, or 2880×1800** (16:10). Use one consistent size, preferably native 2560×1600 if the test display supports it. Capture the installed Store variant after signing and end-to-end testing; do not pass off product art, mockups, or direct-build screenshots as the Store app. Remove personal filenames/paths/account details. Keep the application's real interface and legible controls.

Suggested order:

1. Main branded window with a synthetic, permission-cleared audio file selected and both actions visible.
2. Actual four-stem completed state, with Finder showing the four WAV names if it can be captured clearly and truthfully.
3. Actual Create Karaoke completed state, with the single Karaoke WAV in Finder.
4. Optional first-launch Responsible Use gate; the stale evaluation/licence wording has been removed from the shared UI.

The existing `TemplateApp/Assets.xcassets/AppIcon.appiconset` is the app icon source. Apple derives the App Store icon from the uploaded app; do not substitute the separate Lemon Squeezy marketing logo for a screenshot. App previews are optional. Apple's screenshot upload documentation allows 1–10 screenshots and says the images should communicate the actual user experience.

## Privacy and review preparation

- The Store binary must exclude Sparkle update traffic and commands. Write a separate bundled Store privacy/terms variant before submission. The existing `docs/LEGAL/TEMPLATE_APP_PRIVACY.md` and `TEMPLATE_APP_TERMS.md` both describe the GitHub/Sparkle updater; they cannot be presented as the Store variant's exact behavior.
- Based on the current source, audio stays local; job working files are temporary; the durable cleanup journal contains only ownership/bookmark metadata; operational OSLog entries omit audio and song titles. Verify the **final Store build**, all bundled third-party code, and network behavior before choosing Apple's **“No, we do not collect data from this app”** privacy answer. That answer is a draft, not a filed declaration. Optional browser links may send ordinary browser data to external services; disclose them accurately in the policy.
- Publish and anonymously test the Privacy Policy URL. Apple's privacy questions are app-level and must include third-party integrated code. Keep the answer current if future versions add analytics, accounts, crash telemetry, or network requests.
- Provide App Review contact **name, email, and international-format phone number**. Only the public support email is known from source; do not invent a phone number. No demo account is needed if the final Store app remains account-free.
- Draft review notes: “Stem Separator is a free, offline audio separator for Apple Silicon Macs on macOS 15.1+. On first launch, accept Responsible Use. Choose or drop a WAV/AIFF/MP3/unprotected M4A file under 20 minutes. Click Separate Stems or Create Karaoke, then select an output folder. Four-stem mode writes vocals/drums/bass/other WAVs; karaoke mode writes only one Karaoke WAV. The model and runtime are bundled; separation needs no network access. For a quick test, use the attached/identified synthetic test file [TBD only if supplied]. The original audio is not modified. Optional banner/social links open an external browser. Updates are supplied by the Mac App Store.” Check notes against the signed Store build and attach a rights-cleared test audio if App Review needs one.
- Complete the **age-rating**, **content-rights**, **export-compliance/encryption**, **pricing/tax-category**, **territory**, **privacy**, and any jurisdiction-specific declarations in App Store Connect. The owner must decide EU/EEA Digital Services Act trader status if distributing there; do not infer it from the app being free.
- Apple requires accurate screenshots/metadata and excludes beta, demo, and trial copy from Store submissions. The old evaluation wording in `TemplateApp/UI/ResponsibleUseGateView.swift` was removed; verify the final signed Store binary still shows the approved text.

## Owner input still needed for the listing

1. Exact App Review contact **name and phone number** (email can be the existing support address if desired).
2. Exact legal copyright holder spelling and whether an English-only initial listing is acceptable.
3. Storefront availability and EU/EEA trader declaration if those regions are included.
4. Whether to publish on approval automatically or hold for manual release.
5. Confirmation of the final public privacy/support URLs after the Store-specific pages are published; the engineering team can prepare the pages.

The team can prepare the app record, screenshots, metadata, API automation, and review notes when access is provided. Do not request the owner's private `.p8` key in chat or commit it.

## Apple sources checked

- [App information: name, subtitle, bundle ID, category, rights, age rating, DSA](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Platform version information: description, keywords, support URL, review contact/notes](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [Mac screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Upload screenshots and app previews](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Set a price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
