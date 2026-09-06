# Public installer proof

Both immutable releases passed the `Verify published installer` workflow on clean macOS 14 and 26 hosts. Each job fetched the public DMG, verified its checksum/ticket, mounted and copied the app, validated its signature/ticket, applied quarantine, passed Gatekeeper assessment, and ran the bundled worker with network denied and empty HOME/minimal PATH.

[0.1.0 proof](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/34061634309) · [0.1.1 proof](https://github.com/olivierbedardjazz-star/stem-separator/actions/runs/34061830508).

The local public app also passed native UI separation and the actual updater transition. Human browser/Finder dragging, a fresh account and a second physical Mac GUI session were not performed. See [acceptance](release-acceptance.md).
