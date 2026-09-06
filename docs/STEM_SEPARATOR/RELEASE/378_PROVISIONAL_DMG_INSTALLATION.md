# Slice 378 — Provisional signed DMG installation before Apple

Status: implemented; release proof and coverage limits are recorded in [acceptance](evidence/release-acceptance.md). Depends on: 377. Outcome: the frozen signed candidate survives the intended Finder install route and works from Applications before notarization.

## Exact file work

Change `scripts/prepare_provisional_release_dmg.sh`, `scripts/prepare_release_dmg.sh`, `scripts/verify_signed_app.sh` and `scripts/release_record.py`. Create `Packaging/dmg_settings.py`, `scripts/verify_install_artifact.sh`, `Tests/Release/test_dmg_configuration.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/provisional-install.md`. Reuse `Packaging/InstallerAssets/reference-installer-background.tiff` unchanged.

## Low-level packaging and user flow

Use the 373 release record to choose one signed app. Create a distinct `provisional/Stem-Separator-<version>-<build>-arm64-provisional.dmg`; it must never share the final output path or qualify for publication. The final entry point requires an app-stapled state, even if a caller supplies an old environment bypass flag. Share a layout builder, not a public-release bypass.

Replace raw shell-interpolated Python settings with a checked-in settings module consuming structured values. Copy with symlink/permission preservation, then verify the copied signature and runtime inventory. Reuse numerical Finder geometry from the existing script: window origin (400,530), size (540,380), icon size 80, text 12, app (130,220), Applications (410,220), icon view and hidden tool/sidebar/status surfaces. Reuse the TIFF background; do not redraw its arrow. Set volume/app names to Stem Separator. Confirm these values against the retained reference artifact when available; document measured parity.

Sign the provisional DMG and mount it read-only. Record mounted path and app hash; inspect actual .DS_Store layout, background and /Applications symlink. Drag/copy into `/Applications/Stem Separator.app`, checking for an existing running app first. Never overwrite an active job or delete other product copies. If a previous installed Stem Separator exists, preserve it in a deliberate rollback location and identify the exact bundle launched. Do not rely on Spotlight or last-used Launch Services identity.

Launch the installed copy, exercise first-run/legal/theme, choose/drop one audio file, choose destination, separate offline, reveal/inspect all four WAVs, clear/replace audio, cancel/retry and quit. Check native menu cleanup throughout. Record actual app path, ID, build, Team ID, nested inventory and post-run signature. Installation may require a native OS/admin interaction; ask only if that actual interaction cannot be completed through available authorized tools.

Before notarization, Gatekeeper may reject a quarantined candidate for lack of a ticket. Record the exact condition separately; a narrowly documented local developer test route is not final Gatekeeper proof. Never globally disable Gatekeeper or strip quarantine and later claim a normal downloaded installation passed. Final untouched browser-download proof belongs to 381.

## Dependencies/licences

Only build-time dmgbuild and its pinned dependencies. No runtime additions, no model changes. Use approved background/icon assets. This model-bearing provisional artifact remains local and is not uploaded as a public GitHub asset.

## Tests / exit evidence

Automate settings generation with whitespace/Unicode/apostrophe paths, mount/copy/signature checks and final/provisional separation. Confirm helper runs from the installed path. Capture clean-account results when an interactive account is available; a fresh account is not another physical Mac. Record source SHA, signed-app digest, DMG hash, install path and manual UI outcomes.

## Stop conditions

Broken Finder layout/link, signature changed by copy, stale app ambiguity, helper failure in Applications, or unperformed installation. No Apple submission until the signed runtime and provisional install are actually proven. Do not count a ZIP extraction as this test.
