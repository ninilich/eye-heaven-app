# Contributing to EyeHeaven

## Requirements

- macOS 15+
- Xcode 26+
- Swift 6.2

## Local build (unsigned DMG)

```bash
chmod +x scripts/build_local_dmg.sh
./scripts/build_local_dmg.sh
```

Artifacts in `dist/`:
- `EyeHeaven-<version>-<sha>.dmg`
- `EyeHeaven-<version>-<sha>.sha256`
- `catalog.json` (stereogram catalog, copied from `Stereograms/`)

## CI/CD pipeline

Workflow: `.github/workflows/release-main-unsigned.yml`

- Triggers on push to `main` (except `Stereograms/`, `README.md`, docs-only changes)
- Reads `MARKETING_VERSION` from Xcode build settings
- Creates a new GitHub Release only when `MARKETING_VERSION` is higher than the latest `v*` tag
- Builds unsigned Release DMG on `macos-latest`
- Uploads `dist/*.dmg`, `dist/*.sha256`, and `dist/catalog.json` as release assets

PR checks (`.github/workflows/pr-check.yml`):
- Debug build
- Unit tests
- `MARKETING_VERSION` must be greater than base branch — enforce a version bump on every PR

> The pipeline does not use Apple Developer signing or notarization. Users need to bypass Gatekeeper manually (see README).

## Branch workflow

1. Create a feature branch from `main`: `git checkout -b dev-XYZ`
2. Bump `MARKETING_VERSION` in `EyeHeaven/EyeHeaven.xcodeproj/project.pbxproj`
3. Open a PR to `main` — CI checks run automatically
4. Merge triggers the release workflow

## Stereograms

Images live in `Stereograms/` and are served via `raw.githubusercontent.com`. Commits that only touch `Stereograms/` do not trigger a new app release. See [ADDING_IMAGES.md](ADDING_IMAGES.md) for the full guide.
