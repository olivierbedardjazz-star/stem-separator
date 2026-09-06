# Installed Sparkle transition

**Passed:** public 0.1.0/build100 → public 0.1.1/build101, using the permanent GitHub latest feed and stable Ed25519 identity. XCTest clicked Help → Check for Updates, Install Update, and Install and Relaunch. It observed build101 at the predecessor installation path and a usable relaunched app. The resulting bundle fingerprint equalled the notarized successor.

Signatures/ticket, preferences and existing synthetic audio/results were checked separately; the updated app then passed bundled offline inference, full native separation, and a current-version update check. Logs: `release-a-to-b-update.log`, `post-update-offline.log`, `post-update-native-ui.log`, retained in the local release evidence.

This was an installed app copied from the publicly downloaded DMG into the workspace test installation directory, not an updater running from inside a mounted DMG. See [acceptance and limits](release-acceptance.md).
