#!/bin/bash
#
# Taptique Release Build Script
# Creates signed, notarized DMG with professional styling
#
# PREREQUISITES:
#   - Developer ID Application certificate in Keychain
#   - Notarization credentials stored (see below)
#   - brew install create-dmg fileicon
#
# ONE-TIME SETUP (already done for Keegan):
#   xcrun notarytool store-credentials "notary" \
#       --apple-id "keegandewitt@me.com" \
#       --team-id "G398H44H6X" \
#       --password "YOUR_APP_SPECIFIC_PASSWORD"
#
# REQUIRED FILES (create these before running):
#   scripts/dmg-background.png           - 660x400 background image
#   scripts/ApplicationsFolderIcon.icns  - Applications folder icon
#
# USAGE: ./scripts/build-release-dmg.sh [version]

set -e

# ==================== CONFIGURATION ====================
SCHEME="Taptique"
APP_NAME="Taptique.app"
DMG_NAME="Taptique"
TEAM_ID="G398H44H6X"
DEVELOPER_ID="Developer ID Application: Keegan DeWitt (${TEAM_ID})"
NOTARY_PROFILE="notary"
# =======================================================

# Paths
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="${PROJECT_DIR}/scripts"
BUILD_DIR="${PROJECT_DIR}/release-build"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"

# Version from argument or current date
VERSION="${1:-$(date +%Y.%m.%d)}"
DMG_FILENAME="${DMG_NAME}-${VERSION}.dmg"

echo "========================================"
echo "${SCHEME} Release Build"
echo "Version: ${VERSION}"
echo "========================================"

# [1/8] Clean previous build
echo -e "\n[1/8] Cleaning previous build..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# [2/8] Archive
echo -e "\n[2/8] Archiving..."
xcodebuild archive \
    -project "${PROJECT_DIR}/${SCHEME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    CODE_SIGN_IDENTITY="${DEVELOPER_ID}" \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    CODE_SIGN_STYLE=Manual \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    | xcpretty || xcodebuild archive \
    -project "${PROJECT_DIR}/${SCHEME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    CODE_SIGN_IDENTITY="${DEVELOPER_ID}" \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    CODE_SIGN_STYLE=Manual \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime"

# [3/8] Export with Developer ID signing
echo -e "\n[3/8] Exporting with Developer ID signing..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${SCRIPTS_DIR}/ExportOptions.plist"

# [4/8] Verify code signature
echo -e "\n[4/8] Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${EXPORT_PATH}/${APP_NAME}"
echo "Signature verification passed!"

# [5/8] Notarize the app
echo -e "\n[5/8] Notarizing app..."
echo "Creating zip for notarization..."
ditto -c -k --keepParent "${EXPORT_PATH}/${APP_NAME}" "${BUILD_DIR}/${SCHEME}-notarize.zip"

echo "Submitting to Apple for notarization (this may take several minutes)..."
xcrun notarytool submit "${BUILD_DIR}/${SCHEME}-notarize.zip" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait

# [6/8] Staple notarization ticket
echo -e "\n[6/8] Stapling notarization ticket to app..."
xcrun stapler staple "${EXPORT_PATH}/${APP_NAME}"

# Verify notarization
echo "Verifying notarization..."
spctl --assess --type exec --verbose "${EXPORT_PATH}/${APP_NAME}"
echo "App notarization verified!"

# [7/8] Create DMG
echo -e "\n[7/8] Creating, signing, and notarizing DMG..."
DMG_PATH="${BUILD_DIR}/${DMG_FILENAME}"

# Create staging directory (create-dmg copies CONTENTS of source folder)
STAGING_DIR="${BUILD_DIR}/dmg_staging"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -a "${EXPORT_PATH}/${APP_NAME}" "${STAGING_DIR}/"

# Create Finder alias to /Applications (NOT symlink!)
osascript -e "tell application \"Finder\" to make new alias file at POSIX file \"${STAGING_DIR}\" to POSIX file \"/Applications\" with properties {name:\"Applications\"}"

# Set custom icon on Applications alias to prevent macOS icon vanishing bug
fileicon set "${STAGING_DIR}/Applications" "${SCRIPTS_DIR}/ApplicationsFolderIcon.icns"

# Create, sign, and notarize DMG
/opt/homebrew/bin/create-dmg \
    --volname "${DMG_NAME}" \
    --volicon "${EXPORT_PATH}/${APP_NAME}/Contents/Resources/AppIcon.icns" \
    --background "${SCRIPTS_DIR}/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --icon "${APP_NAME}" 180 200 \
    --hide-extension "${APP_NAME}" \
    --icon "Applications" 480 200 \
    --codesign "${DEVELOPER_ID}" \
    --notarize "${NOTARY_PROFILE}" \
    "${DMG_PATH}" \
    "${STAGING_DIR}"

# Cleanup staging directory
rm -rf "${STAGING_DIR}"

echo "DMG created, signed, and notarized: ${DMG_PATH}"

# [8/8] Verify DMG
echo -e "\n[8/8] Verifying DMG..."
spctl --assess --type open --context context:primary-signature --verbose "${DMG_PATH}"

# Cleanup
rm -f "${BUILD_DIR}/${SCHEME}-notarize.zip"

# Done
echo -e "\n========================================"
echo "BUILD COMPLETE!"
echo "========================================"
echo ""
echo "DMG location: ${DMG_PATH}"
echo "DMG size: $(du -h "${DMG_PATH}" | cut -f1)"
echo ""
echo "To test Gatekeeper acceptance:"
echo "  spctl --assess --type open -v ${DMG_PATH}"
echo ""
