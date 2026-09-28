#!/bin/bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build
signing_identity="${THAW_SIGNING_IDENTITY:-Thaw Local Code Signing}"
if ! security find-identity -v -p codesigning | grep -F -- "$signing_identity" >/dev/null; then
  printf 'Missing stable code-signing identity: %s. Run scripts/setup-local-signing.sh once after approving the keychain change.\n' "$signing_identity" >&2
  exit 1
fi
xcodebuild build -project Thaw.xcodeproj -scheme Thaw -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO \
  MARKETING_VERSION=2.0.1-local.2 CURRENT_PROJECT_VERSION=56
app="$repo_root/build/DerivedData/Build/Products/Release/Thaw.app"
/usr/libexec/PlistBuddy -c 'Set :ThawRepositoryURL https://github.com/Gy-Hu/Thaw' "$app/Contents/Info.plist"
# Reuse the same certificate and bundle identifier on every build so the
# designated requirement can remain stable across updates. Never silently fall
# back to ad-hoc signing, which would require a new privacy authorization.
codesign --force --deep --sign "$signing_identity" --options runtime --timestamp=none "$app"
codesign --verify --deep --strict "$app"
# Xcode registers build products; only the installed copy should be selected by
# Privacy settings when several bundles share this identifier.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$app"
printf '\nLocal build: %s\n' "$app"
