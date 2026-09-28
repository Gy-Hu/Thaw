#!/bin/bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
mkdir -p build
xcodebuild build -project Thaw.xcodeproj -scheme Thaw -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO \
  MARKETING_VERSION=2.0.1-local.2 CURRENT_PROJECT_VERSION=56
app="$repo_root/build/DerivedData/Build/Products/Release/Thaw.app"
/usr/libexec/PlistBuddy -c 'Set :ThawRepositoryURL https://github.com/Gy-Hu/Thaw' "$app/Contents/Info.plist"
# Sign nested frameworks, helper apps and the main executable together. This is
# a local ad-hoc build, not an Apple-notarized distribution. XPC authenticates
# both endpoints with the bundled code hashes when no Team ID is available.
codesign --force --deep --sign - --options runtime --timestamp=none "$app"
codesign --verify --deep --strict "$app"
# Xcode registers build products; only the installed copy should be selected by
# Privacy settings when several bundles share this identifier.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$app"
printf '\nLocal build: %s\n' "$app"
