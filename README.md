# EyeHeaven

EyeHeaven is a macOS menu bar app that helps reduce eye strain with timed short and long breaks.

**Features:**
- Short and long break scheduling with configurable intervals
- Pre-break warning banner
- Full-screen break mode with background dimming
- Optional stereogram display during long breaks
- Focus Mode / Do Not Disturb awareness
- Idle detection (no permissions required)
- 9-language interface

## Download

1. Open the [Releases page](https://github.com/ninilich/eye-heaven-app/releases) and download the latest DMG.
2. Open the DMG and drag **EyeHeaven.app** to Applications.
3. First launch — right-click the app and choose **Open**, then confirm.

If macOS shows _"damaged and can't be opened"_, run:

```bash
xattr -dr com.apple.quarantine /Applications/EyeHeaven.app
```

## Verify integrity

Each release includes a `.sha256` file:

```bash
shasum -a 256 EyeHeaven-<version>.dmg
```

Compare the output with the checksum in the release assets.

## Legal

- License: GPL-3.0 — see [LICENSE](LICENSE)
- Privacy Policy — see [PRIVACY.md](PRIVACY.md)
- Anonymous usage telemetry (Heartbeat) can be disabled: **Settings → System → Heartbeat**

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build instructions, CI/CD pipeline details, and development workflow.

To add stereogram images to the catalog, see [ADDING_IMAGES.md](ADDING_IMAGES.md).
