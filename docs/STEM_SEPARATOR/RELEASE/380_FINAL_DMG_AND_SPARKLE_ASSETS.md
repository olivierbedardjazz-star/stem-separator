# Slice 380 — Final DMG, update ZIP and signed feed

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 379. Outcome: an exact, complete set of distributable artifacts made from the stapled app without rebuilding it.

## Exact file work

Change `scripts/prepare_release_dmg.sh`, `scripts/notarize_release_dmg.sh`, `scripts/prepare_sparkle_release.sh`, `scripts/locate_sparkle_bin.sh`, `scripts/ensure_sparkle_keys.sh`, `scripts/release_record.py`. Create `scripts/verify_release_assets.py`, `Tests/Release/test_release_assets.py`, `docs/STEM_SEPARATOR/RELEASE/evidence/final-artifacts.md`, and `docs/STEM_SEPARATOR/RELEASE/notes/0.1.0.md` (later `0.1.1.md` in 382). Use `Packaging/dmg_settings.py` from 378.

## Exact artifact contract

- `Stem-Separator-<version>-<build>-arm64.dmg`: human first installation, signed and notarized/stapled container.
- `Stem-Separator-<version>-<build>-arm64.zip`: one top-level `Stem Separator.app`, the same stapled app, EdDSA-signed for Sparkle. ZIP itself does not receive a staple.
- `appcast.xml`: generated, signed feed targeting that release's immutable ZIP URL.
- `SHA256SUMS.txt` and `release-manifest.json`: public artifact integrity/provenance summary with no local secrets/paths.
- Release notes: embed in the signed feed for v1; avoid an extra external notes-signature hosting dependency.

## Low-level sequence

1. Require verified app-stapled state, current signature/model/helper manifest and correct stable ID/feed/key/version. Do not rebuild, strip, change plist, regenerate notices or re-sign the app. Compute payload identities before packaging and after extraction of each final container.
2. Build the final DMG with the same tested layout/copy semantics as 378, distinct final path. Sign the DMG. Submit that explicit DMG path to Apple; eliminate lexical newest-DMG discovery. Use the same structured Accepted/log/state rules as 379. Staple/validate DMG, run the appropriate disk-image Gatekeeper assessment and mount/verify its app. Hash the final DMG after ticket attachment.
3. Create the ZIP directly from the stapled app with preserved symlinks, modes and metadata. Confirm one app at archive root, no build/test files, and restored app/helper signatures, IDs and ticket. Hash this ZIP before Sparkle metadata generation.
4. Resolve generate_appcast from the pinned 2.9.5 artifact. Verify the local account public key matches the built app. Stage exactly the intended ZIP and notes; no wildcard collection of old ZIPs. Generate with deltas disabled and the explicit `https://github.com/olivierbedardjazz-star/stem-separator/releases/download/v<version>/` prefix. Retain signed-feed and verify-before-extraction protections.
5. For v1 the generated feed carries only the current supported item. This avoids rewriting old-version URLs under a new tag; older binaries remain in their releases. Verify enclosure URL, version/build, minimum OS/architecture constraints, length and signature against exact ZIP. No hand-editing XML after signing. Check feed-signature behavior with the pinned tool/library, not a guessed detached-signature scheme.
6. Write the final local/public records only after all bytes are final. Avoid circular hashing: SHA256SUMS lists named payload assets; a record does not hash itself. Record full paths locally, relative asset names publicly. Preparation never uploads or calls archive/export.

## UI/dependencies/licences

DMG is the only advertised install method. Same worker, model and notices as accepted app; no dependency upgrades. Feed release notes describe user changes, not build-system details. App update requests remain ordinary HTTPS to GitHub, with no authentication token embedded.

## Tests / stop conditions

Test stale staple record, provisional DMG selection, wrong ZIP root, changed byte length/hash, wrong feed key/repo/version, unsigned feed, old URL preservation and no-deltas policy. Restore ZIP and DMG copies, compare signed content and run helper proof on restored copies. Stop for failed DMG acceptance/ticket, stale key, any unsigned/tampered feed/archive or differences from the accepted app beyond preserved ticket/container metadata.
