#!/usr/bin/env bash
# Build Silicon Stats.app (Release) and package a UDZO DMG.
# Intended for macOS hosts / GitHub Actions macos runners.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="Silicon Stats"
PROJECT="SiliconStats.xcodeproj"
CONFIG="Release"
DERIVED="${DERIVED_DATA_PATH:-$ROOT/build/DerivedData}"
DIST="${DIST_PATH:-$ROOT/dist}"

# Prefer explicit VERSION; fall back to git tag / marketing version.
VERSION="${VERSION:-}"
if [[ -z "$VERSION" ]]; then
  if git describe --tags --exact-match HEAD >/dev/null 2>&1; then
    VERSION="$(git describe --tags --exact-match HEAD)"
  else
    VERSION="$(git describe --tags --always --dirty 2>/dev/null || echo "0.0.0-dev")"
  fi
fi
# Strip leading v for CFBundleShortVersionString-style names when present.
VERSION_NUM="${VERSION#v}"

APP_NAME="SiliconStats"
DMG_NAME="SiliconStats-${VERSION_NUM}.dmg"

mkdir -p "$DIST" "$DERIVED"

echo "==> Building $SCHEME ($CONFIG) version $VERSION_NUM"

# Ad-hoc sign by default so CI without Apple Developer certs still produces a runnable .app.
# Set CODE_SIGN_IDENTITY / DEVELOPMENT_TEAM in the environment for Developer ID builds.
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIG"
  -derivedDataPath "$DERIVED"
  -destination "generic/platform=macOS"
  ONLY_ACTIVE_ARCH=NO
  MARKETING_VERSION="$VERSION_NUM"
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}"
)

if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  XCODEBUILD_ARGS+=(DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM")
  XCODEBUILD_ARGS+=(CODE_SIGN_STYLE=Automatic)
else
  XCODEBUILD_ARGS+=(CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY")
  XCODEBUILD_ARGS+=(CODE_SIGNING_REQUIRED=NO)
  XCODEBUILD_ARGS+=(CODE_SIGNING_ALLOWED=YES)
fi

xcodebuild "${XCODEBUILD_ARGS[@]}" build

APP_PATH="$(find "$DERIVED/Build/Products/$CONFIG" -maxdepth 1 -name "*.app" -print -quit)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "error: built .app not found under $DERIVED/Build/Products/$CONFIG" >&2
  exit 1
fi

echo "==> Found app: $APP_PATH"
STAGE="$DIST/dmg-root"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"

# Optional Applications symlink for drag-install UX.
ln -sf /Applications "$STAGE/Applications"

DMG_PATH="$DIST/$DMG_NAME"
rm -f "$DMG_PATH"

echo "==> Creating $DMG_PATH"
hdiutil create \
  -volname "Silicon Stats $VERSION_NUM" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

# Emit GitHub Actions outputs when available.
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dmg_path=$DMG_PATH"
    echo "dmg_name=$DMG_NAME"
    echo "version=$VERSION_NUM"
    echo "app_path=$APP_PATH"
  } >> "$GITHUB_OUTPUT"
fi

echo "==> Done: $DMG_PATH"
ls -lh "$DMG_PATH"
