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

Stereogram images live in the `Stereograms/` folder and are served via `raw.githubusercontent.com`.

1. Add image files (`.jpg`, reasonable file size) to `Stereograms/`.
2. Add an entry to `Stereograms/catalog.json`:
   ```json
   {
     "id": "my-image",
     "filename": "my-image.jpg",
     "url": "https://raw.githubusercontent.com/ninilich/eye-heaven-app/main/Stereograms/my-image.jpg",
     "source": "https://example.com",
     "author": "Author Name"
   }
   ```
3. Commit and push to `main`. No new app release is triggered for `Stereograms/`-only changes.
4. Verify in app: Settings → Stereograms → Update Now.
