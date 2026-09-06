# Slice 381 — Publish exact artifacts and test the download

Status: pending. Depends on: 380. Outcome: the public repository serves complete verified assets and a user can install the real download normally.

## Exact file work

Change `scripts/publish_github_release.sh`, `scripts/release_preflight.sh`, `scripts/release_record.py`, `README.md`. Create `scripts/verify_published_release.py`, `Tests/Release/test_publication.py`, and `docs/STEM_SEPARATOR/RELEASE/evidence/published-install.md`.

## Low-level publication flow

1. Require the release record's final accepted/stapled assets, exact source tag SHA and matching source/release repository. Recheck local hashes, sizes, notes and signed feed. Verify gh account access to this repository without echoing tokens. Do not assume `gh auth status` alone proves write access.
2. Create the version tag pointing to the proven source SHA, never force-move an existing release tag. Use local authenticated gh to prepare a draft release with DMG, ZIP, feed, checksum and public manifest, explicit notes and title. Publishing does not run preparation/build/signing scripts. Source is already public; draft assets are not the live update channel.
3. Verify uploaded draft assets through authenticated access by hashes/sizes before publication. On interrupted upload, resume only missing or byte-identical assets. Refuse conflicting bytes under an existing name/version. Remove current `--clobber`, lexical ZIP discovery and `PREPARE_RELEASE=1` behavior.
4. Publish the complete release as a normal release and explicitly set latest only when its full asset set is ready. The stable feed resolves to `releases/latest/download/appcast.xml`; drafts/prereleases are not assumed to work there. Publication of A in 382 is deliberately public, not a private test.
5. Download feed and every advertised asset anonymously over HTTPS, follow expected GitHub redirects, verify hashes/length/signatures and tag-target identity. Confirm latest resolves to the intended release, and checksum/manifest/notes agree. Retry boundedly for propagation; never treat a metadata-only successful upload as artifact verification.
6. Update README's prominent install link to the Releases page/DMG. Avoid changing signed app bytes for website copy. Mark publication evidence separately from installed proof. If a publication fails, keep the prior latest release where possible; diagnose before advancing the feed. Do not replace a bad published binary in place.

## Real installation flow

Download the final DMG using a normal browser path on an available clean account or second Mac; retain normal quarantine. Mount, drag into Applications, launch exact installed build, accept first-run notice, choose/drop audio, separate offline, inspect/reveal WAVs, cancel/retry, use legal/theme/menu surfaces and check updates. Verify app and DMG tickets/signatures, installed version/helper identity and unmodified source audio. Confirm no Python/model download/install prompt occurs.

CI can additionally download/mount/audit the public payload, but a hosted runner cannot be presented as the human Finder/Gatekeeper proof. Record hardware, OS, account cleanliness and installed path; test macOS 14 if claiming that floor. If only this Mac is available, explicitly report that limitation and keep unperformed second-machine claims pending. Never remove quarantine or disable Gatekeeper to turn a final download failure into a pass. Address required admin/OS interaction only when encountered.

## Dependencies/licences and evidence

No new app dependencies. Public hosting exposes source and model-bearing binaries, so 370 clearance applies. Logs/screenshots must be sanitized before publishing. Keep submission logs/private machine paths in ignored local evidence. Record exact public URLs and downloaded-byte hashes.

## Tests / stop conditions

Mock wrong repo, wrong tag, asset collision, interrupted upload, failed anonymous fetch, stale latest feed and mismatched ZIP checksum. Live final downloaded install is mandatory. Stop announcement/completion for broken latest URL, rejected signature/ticket, unexpected installer prompt, source/runtime mismatch or missing installed workflow proof. Later fixes use a higher build with renewed gates.
