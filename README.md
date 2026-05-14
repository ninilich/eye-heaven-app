# EyeHeaven

EyeHeaven is a macOS menu bar app that helps reduce eye strain with timed short and long breaks.

Main features:
- Short and long break scheduling
- Pre-break warning banner
- Full-screen break mode with configurable dimming
- Optional stereogram mode during long breaks
- Focus Mode and idle detection support
- Multi-language interface

## Download and Install (DMG from GitHub Releases)

1. Open the Releases page and download the latest DMG.
2. Open the DMG and drag EyeHeaven.app to Applications.
3. First launch (unsigned build):
   - Right-click EyeHeaven.app and choose Open.
   - Confirm Open in the macOS dialog.

If macOS still blocks launch, run:

```bash
xattr -dr com.apple.quarantine /Applications/EyeHeaven.app
```

## Verify Download Integrity

Each release includes a `.sha256` file.

```bash
shasum -a 256 EyeHeaven-<file>.dmg
```

Compare the output with the checksum in the release asset.

## Local Build (Unsigned DMG)

Requirements:
- macOS
- Xcode 26+
- Command Line Tools

Run:

```bash
chmod +x scripts/build_local_dmg.sh
./scripts/build_local_dmg.sh
```

Artifacts are produced in `dist/`:
- `*.dmg`
- `*.sha256`

## CI/CD (GitHub Actions)

Workflow file: `.github/workflows/release-main-unsigned.yml`

Behavior:
- Triggered on push to `main` (or manually via workflow_dispatch)
- Reads `MARKETING_VERSION` from Xcode build settings
- Publishes a new release only when `MARKETING_VERSION` increased versus existing `v*` tags
- Builds unsigned Release DMG on macOS runner
- Publishes assets to release tag `v<MARKETING_VERSION>`

Note: this pipeline does not use Apple Developer signing or notarization.

## Legal

- License: GNU General Public License v3.0 (GPL-3.0), see `LICENSE`.
- Privacy Policy: see `PRIVACY.md`.
- Anonymous telemetry (Heartbeat) can be disabled in app settings:
   Settings -> System -> Heartbeat.

## How to Add Stereograms

1. Prepare image files (`.jpg` or `.png`, reasonable file size, lowercase hyphenated names).
2. Update `catalog.json` and add an entry to `images` with:
   - `id`
   - `filename`
   - `url`
   - optional `source`
   - optional `author`
3. Bump `catalog.json` `version`.
4. Create or update the latest GitHub release and attach:
   - updated `catalog.json`
   - all new images
   - all previously released images required by the current catalog
5. Verify in app:
   - Settings -> Stereograms -> Update Now
   - Trigger a long break and confirm image + attribution
