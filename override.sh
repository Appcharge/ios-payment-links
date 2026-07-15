#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  FULL AUTO DESTRUCTIVE OVERRIDE + COCOAPODS DELETE
#
#  Usage:
#      ./override.sh <version> [ignored extra args]
#
#  Example:
#     ./override.sh 5.0.8 --allow-warnings --notes Release-Notes.md
#
#  This script:
#    1) Uses the first argument as <version>, ignores the rest
#    2) If possible, runs:
#         pod trunk delete ios-payment-links <version>
#    3) AUTO-COMMITS any local changes so the working tree is clean
#    4) Checks out TARGET_BRANCH (master by default)
#    5) Creates a SINGLE clean commit with current files (orphan reset)
#    6) Deletes the specific tag <version> locally (if exists)
#    7) Force-pushes clean history to origin (TARGET_BRANCH)
#    8) Deletes the specific tag <version> on origin (if exists)
#
#  Notes:
#    - This COMPLETELY rewrites GitHub history for this repo on TARGET_BRANCH.
#    - This is destructive. Use only if you know what you're doing.
# ============================================================

TARGET_BRANCH="main"
REMOTE="origin"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version> [ignored extra args]"
  exit 1
fi

VERSION="$1"
TAG_NAME="$VERSION"      # if your tags are like v3.1.1, change to TAG_NAME="v$VERSION"
shift || true            # ignore extra flags

echo "⚠️ WARNING: Destructive operation!"
echo "   Will attempt to DELETE ios-payment-links version ${VERSION} from CocoaPods trunk (if present)"
echo "   Will rewrite Git history on branch '${TARGET_BRANCH}'"
echo "   Will delete tag: ${TAG_NAME} (local + remote if exists)"
echo ""

# ── Step 1: Try delete version from CocoaPods trunk (best-effort) ─────────────
if command -v pod >/dev/null 2>&1; then
  echo "📦 Checking CocoaPods trunk for ios-payment-links ${VERSION}..."
  if pod trunk info ios-payment-links 2>/dev/null | grep -wq "${VERSION}"; then
    echo "🗑 Attempting DELETE of ios-payment-links ${VERSION}…"

    if pod trunk delete ios-payment-links "${VERSION}"; then
      echo "✅ Successfully deleted ios-payment-links ${VERSION} from CocoaPods trunk!"
    else
      echo "❌ DELETE failed for version ${VERSION}."
      echo "ℹ️ Continuing anyway (repo override still proceeds)."
    fi
  else
    echo "ℹ️ Version ${VERSION} does NOT exist on trunk. Nothing to delete."
  fi
else
  echo "ℹ️ 'pod' not installed. Skipping trunk delete."
fi

# ── Step 2: Ensure we are in a git repo ───────────────────────────────────────
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not inside a git repository."
  exit 1
fi

# ── Step 3: Auto-fix dirty working tree (commit everything) ───────────────────
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  echo "🧹 Working tree is not clean. Auto-committing all changes before override..."
  git status --short || true
  git add -A
  # commit may fail if nothing staged after add -A; ignore that
  git commit -m "Auto-commit before override for version ${VERSION}" || true
else
  echo "✅ Working tree is already clean."
fi

# ── Step 4: Basic git repo & branch checks ────────────────────────────────────
# FIX: if master doesn't exist locally, fetch/create it from origin
if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  echo "ℹ️ Target branch '$TARGET_BRANCH' does not exist locally. Trying to fetch from $REMOTE..."
  git fetch "$REMOTE" "$TARGET_BRANCH":"$TARGET_BRANCH" 2>/dev/null || true
fi

if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  echo "❌ Target branch '$TARGET_BRANCH' does not exist locally or on remote."
  echo "   Available local branches:"
  git branch --list || true
  echo "   Available remote branches:"
  git branch -r || true
  exit 1
fi

REMOTE_URL="$(git remote get-url "$REMOTE" 2>/dev/null || true)"
if [[ -z "$REMOTE_URL" ]]; then
  echo "❌ No '$REMOTE' remote configured."
  exit 1
fi

echo "📍 Repo:          $(basename "$(pwd)")"
echo "📍 Remote:        ${REMOTE_URL}"
echo "📍 Target branch: ${TARGET_BRANCH}"

# ── Step 5: Fetch latest from remote ──────────────────────────────────────────
git fetch "$REMOTE"

# ── Step 6: Start from TARGET_BRANCH ──────────────────────────────────────────
git checkout "$TARGET_BRANCH"

# ── Step 7: Create a clean orphan commit based on TARGET_BRANCH content ───────
TEMP="clean_reset_$RANDOM"
echo "==> Creating orphan branch ${TEMP} with current '${TARGET_BRANCH}' contents"

git checkout --orphan "$TEMP"

# Clear index & workspace, then restore files from TARGET_BRANCH
git rm -rf . >/dev/null 2>&1 || true
git checkout "$TARGET_BRANCH" -- . >/dev/null 2>&1

git add -A
git commit -m "Clean history after override for version ${VERSION}"

# ── Step 8: Delete specific local tag (if exists) ─────────────────────────────
# FIX: use tag-specific ref check (more reliable than rev-parse)
if git show-ref --tags --verify --quiet "refs/tags/$TAG_NAME"; then
  echo "🗑 Deleting local tag: $TAG_NAME"
  git tag -d "$TAG_NAME"
else
  echo "ℹ️ Local tag $TAG_NAME does not exist. Skipping local delete."
fi

# ── Step 9: Replace TARGET_BRANCH with clean orphan commit ────────────────────
git branch -M "$TARGET_BRANCH"

# ── Step 10: Force push clean branch to origin ────────────────────────────────
echo "🚀 Force-pushing rewritten '${TARGET_BRANCH}' to ${REMOTE}"
git push "$REMOTE" "$TARGET_BRANCH" --force

# ── Step 11: Delete specific remote tag (if exists) ───────────────────────────
if git ls-remote --tags "$REMOTE" "refs/tags/$TAG_NAME" | grep -q "refs/tags/$TAG_NAME"; then
  echo "🗑 Deleting remote tag: $TAG_NAME from $REMOTE"
  git push "$REMOTE" ":refs/tags/$TAG_NAME"
else
  echo "ℹ️ Remote tag $TAG_NAME does not exist on $REMOTE. Skipping remote delete."
fi

echo ""
echo "🎉 DONE!"
echo " - Attempted delete of ios-payment-links ${VERSION} from CocoaPods trunk"
echo " - Auto-committed any local changes before override"
echo " - Repo history on '${TARGET_BRANCH}' rewritten to a single clean commit"
echo " - Local/remote tag '${TAG_NAME}' removed (if it existed)"
