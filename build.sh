#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./build.sh <version> [--allow-warnings] [--notes path/to/Notes.md] [--override]
#
# Example:
#   ./build.sh 1.0.0 --allow-warnings --notes Release-Notes.md

##############################################
# build.sh — SPM-only publish (GitHub Release ZIP + checksum)
##############################################

##############################################
# STEP 0 — Read inputs + flags (compat mode)
# - Keeps --allow-warnings only for backward compatibility (ignored).
# - Uses --notes <file> as GitHub Release notes body.
##############################################
VERSION="${1:-}"
shift || true

NOTES_FILE="Release-Notes.md"
ALLOW_WARNINGS=""   # kept for compatibility; not used in SPM flow
OVERRIDE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes)
      NOTES_FILE="${2:-}"
      shift 2
      ;;
    --allow-warnings)
      ALLOW_WARNINGS="--allow-warnings" # compatibility only
      shift
      ;;
    --override)
      OVERRIDE="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  echo "❌ Version missing"
  echo "Usage: ./build.sh <version> [--allow-warnings] [--notes Release-Notes.md] [--override]"
  exit 1
fi

##############################################
# STEP 1 — Config (Repo is EMPTY and SPM-only)
##############################################
REPO_HTTPS="https://github.com/Appcharge/ios-payment-links.git"
REPO_NAME="Appcharge/ios-payment-links"
DEFAULT_BRANCH="master"

XCFRAMEWORK_DIR="ACPaymentLinks.xcframework"
ZIP_NAME="ACPaymentLinks.xcframework.zip"

# Podspec is optional: we do NOT modify it, and we do NOT run CocoaPods steps.
PODSPEC="$(ls *.podspec 2>/dev/null | head -n 1 || true)"

# URL where the Release asset will be hosted (stable format)
ASSET_URL="https://github.com/Appcharge/ios-payment-links/releases/download/${VERSION}/${ZIP_NAME}"

##############################################
# STEP 2 — Validate required files exist (SPM set)
##############################################
echo "🔎 [STEP 2] Validating required files..."

[[ -d "$XCFRAMEWORK_DIR" ]] || { echo "❌ Missing $XCFRAMEWORK_DIR in $(pwd)"; exit 1; }
[[ -f "README.md" ]] || { echo "❌ Missing README.md in $(pwd)"; exit 1; }
[[ -f "LICENSE" ]] || { echo "❌ Missing LICENSE in $(pwd)"; exit 1; }
[[ -f "$NOTES_FILE" ]] || { echo "❌ Missing notes file: $NOTES_FILE"; exit 1; }

echo "✔ Required files are present"

##############################################
# STEP 2.5 — FIX nested XCFramework (xcframework inside xcframework)
# Keeps your flow identical, only fixes the folder if it is nested like:
# ACPaymentLinks.xcframework/ACPaymentLinks.xcframework/...
##############################################
NESTED_PATH="${XCFRAMEWORK_DIR}/${XCFRAMEWORK_DIR}"
if [[ -d "$NESTED_PATH" ]]; then
  echo "🧹 [STEP 2.5] Found nested XCFramework: $NESTED_PATH"
  echo "    Flattening to keep only one XCFramework root..."

  TMP_DIR="$(mktemp -d)"
  mv "$NESTED_PATH" "$TMP_DIR/inner.xcframework"

  # remove the outer (broken) container
  rm -rf "$XCFRAMEWORK_DIR"

  # move the valid inner framework back to the correct name
  mv "$TMP_DIR/inner.xcframework" "$XCFRAMEWORK_DIR"
  rm -rf "$TMP_DIR"

  echo "✔ Nested XCFramework flattened"
fi

##############################################
# STEP 3 — Initialize git repo if needed + set remote to EMPTY repo
##############################################
echo "📦 [STEP 3] Initializing / syncing Git repo..."

if [[ ! -d ".git" ]]; then
  git init
fi

# Ensure correct remote
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REPO_HTTPS"
else
  git remote add origin "$REPO_HTTPS"
fi

# Ensure we are on master (create/reset branch if needed)
git checkout -B "$DEFAULT_BRANCH" >/dev/null 2>&1 || true

##############################################
# STEP 4 — Create ZIP artifact for SPM Release (NOT committed)
# - MUST use --keepParent so SwiftPM recognizes the XCFramework correctly.
##############################################
echo "📦 [STEP 4] Creating ZIP artifact: $ZIP_NAME"
rm -f "$ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_DIR" "$ZIP_NAME"
echo "✔ ZIP created: $ZIP_NAME"

##############################################
# STEP 5 — Compute SHA256 checksum for Package.swift
##############################################
echo "🔐 [STEP 5] Computing SHA256 checksum..."
CHECKSUM="$(swift package compute-checksum "$ZIP_NAME")"
echo "✔ Checksum: $CHECKSUM"

##############################################
# STEP 6 — Generate a VALID Package.swift (do not patch/regex)
# - This guarantees the manifest is always valid for SwiftPM/Xcode.
##############################################
echo "🧩 [STEP 6] Generating Package.swift (url + checksum)..."

cat > Package.swift <<EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ios-payment-links",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ACPaymentLinks",
            targets: ["ACPaymentLinks"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "ACPaymentLinks",
            url: "${ASSET_URL}",
            checksum: "${CHECKSUM}"
        )
    ]
)
EOF

echo "✔ Package.swift generated"

##############################################
# STEP 7 — Stage ONLY the allowed files (SPM set)
# - Explicitly excludes scripts and the ZIP (ZIP goes only to GitHub Release).
##############################################
echo "📦 [STEP 7] Staging allowed files only..."

# Clear index from previous runs
git rm -r --cached . >/dev/null 2>&1 || true

# Required allowed files
git add -f \
  "$XCFRAMEWORK_DIR" \
  Package.swift \
  README.md \
  LICENSE \
  "$NOTES_FILE"

# Optional podspec (only if exists)
if [[ -n "${PODSPEC}" && -f "${PODSPEC}" ]]; then
  git add -f "${PODSPEC}"
fi

echo "✔ Allowed files staged"

##############################################
# STEP 8 — Commit (create initial commit if repo is empty)
##############################################
echo "📝 [STEP 8] Committing..."
git commit -m "Release ${VERSION} (SPM)" || echo "⚠️ Nothing to commit"

##############################################
# STEP 9 — Push branch (handles non-empty remote)
##############################################
echo "⬆️ [STEP 9] Pushing branch: $DEFAULT_BRANCH"

git fetch origin "$DEFAULT_BRANCH" >/dev/null 2>&1 || true

if git ls-remote --heads origin "$DEFAULT_BRANCH" | grep -qE "[[:space:]]refs/heads/${DEFAULT_BRANCH}$"; then
  echo "⚠️ Remote branch '$DEFAULT_BRANCH' exists — forcing push (SPM reset mode)."
  git push -u origin "$DEFAULT_BRANCH" --force
else
  echo "✅ Remote branch '$DEFAULT_BRANCH' does not exist yet — normal push."
  git push -u origin "$DEFAULT_BRANCH"
fi

echo "✔ Branch pushed"

##############################################
# STEP 10 — Tag handling (delete if exists, recreate, push)
##############################################
echo "🏷 [STEP 10] Tagging release: ${VERSION}"

git tag -d "$VERSION" 2>/dev/null || true
git push origin ":refs/tags/$VERSION" 2>/dev/null || true

git tag "$VERSION"
git push origin "$DEFAULT_BRANCH"
git push origin "$VERSION"

echo "✔ Tag pushed"

##############################################
# STEP 11 — Create GitHub Release + upload ZIP asset (SPM only)
##############################################
echo "🚀 [STEP 11] Creating GitHub Release + uploading ZIP..."

if command -v gh >/dev/null 2>&1; then
  gh release delete "$VERSION" -y >/dev/null 2>&1 || true

  gh release create "$VERSION" \
    "$ZIP_NAME" \
    --title "$VERSION" \
    --notes-file "$NOTES_FILE" \
    --latest

  echo "✔ GitHub Release created (asset uploaded): $ZIP_NAME"
else
  echo "❌ gh not installed — cannot create GitHub Release automatically"
  echo "   Install: brew install gh"
  exit 1
fi

###########################################################
# STEP 12 — SEND SLACK NOTIFICATION
###########################################################
if [[ -f "./slack_notify.sh" ]]; then
  echo "🚀 [STEP 12] Running Slack notifier..."

  ./slack_notify.sh \
    "$REPO_NAME" \
    "production" \
    "success" \
    "Version $VERSION published successfully" \
    "$(cat "$NOTES_FILE")"

  echo "✔ Slack notification executed"
else
  echo "⚠️ slack_notify.sh not found — skipping Slack notification"
fi

##############################################
# STEP 13 — Done (SPM-only)
##############################################
echo ""
echo "✅ SPM release flow complete!"
echo "• Repo: $REPO_NAME"
echo "• Tag: $VERSION"
echo "• Asset URL: $ASSET_URL"
echo "• Checksum: $CHECKSUM"
echo ""
