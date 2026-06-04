#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/EyeHeaven/EyeHeaven.xcodeproj"
SCHEME="EyeHeaven"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
DIST_DIR="$ROOT_DIR/dist"

CHANNEL="${CHANNEL:-local}"
APP_NAME="EyeHeaven.app"
VOLUME_NAME="EyeHeaven"
SHORT_SHA="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo "nogit")"
TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"

if [[ "$CHANNEL" == "local" ]]; then
  ARTIFACT_BASENAME="EyeHeaven-${TIMESTAMP}-${SHORT_SHA}"
else
  ARTIFACT_BASENAME="EyeHeaven-${CHANNEL}-${SHORT_SHA}"
fi

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"
DMG_PATH="$DIST_DIR/${ARTIFACT_BASENAME}.dmg"
SHA_PATH="$DIST_DIR/${ARTIFACT_BASENAME}.sha256"

mkdir -p "$DIST_DIR"

echo "==> Building $SCHEME ($CONFIGURATION)"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build finished but app not found: $APP_PATH" >&2
  exit 1
fi

echo "==> Creating DMG: $DMG_PATH"
rm -f "$DMG_PATH" "$SHA_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> Calculating SHA256"
shasum -a 256 "$DMG_PATH" > "$SHA_PATH"

echo "==> Copying catalog.json"
CATALOG_SRC="$ROOT_DIR/Stereograms/catalog.json"
if [[ -f "$CATALOG_SRC" ]]; then
  cp "$CATALOG_SRC" "$DIST_DIR/catalog.json"
  echo "  catalog.json copied"
else
  echo "  WARNING: Stereograms/catalog.json not found, skipping"
fi

echo "Build artifacts:"
echo "  DMG: $DMG_PATH"
echo "  SHA: $SHA_PATH"
echo "  catalog.json: $DIST_DIR/catalog.json"
