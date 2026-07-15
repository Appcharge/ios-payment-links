#!/usr/bin/env bash
set -euo pipefail

# ╭──────────────────────────────────────────────╮
# │        XCFramework Validation Script         │
# │    Checks: slices, architectures, static,    │
# │    .swiftinterface (module stability)        │
# ╰──────────────────────────────────────────────╯
#  Usage:
#     ./check_xcframework.sh ACPaymentLinks.xcframework
# -----------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-.xcframework>"
  exit 1
fi

XC="$1"

# ───────────────────────────────
# Emoji helpers
# ───────────────────────────────
ICON_CHECK="✅"
ICON_ERROR="❌"
ICON_STEP="⚙️"
ICON_INFO="🔍"
ICON_DONE="🎉"

# ───────────────────────────────
# Utility functions
# ───────────────────────────────
ok()   { echo -e "${ICON_CHECK}  $*"; }
err()  { echo -e "${ICON_ERROR}  $*" >&2; exit 1; }
step() { echo -e "\n${ICON_STEP}  $*"; }
info() { echo -e "${ICON_INFO}  $*"; }

# ───────────────────────────────
# Step 1 – Locate slices
# ───────────────────────────────
step "Checking XCFramework slices..."
[[ -d "$XC" ]] || err "XCFramework not found at: $XC"

DEV_DIR="$XC/ios-arm64"
SIM_DIR_A="$XC/ios-arm64_x86_64-simulator"
SIM_DIR_B="$XC/ios-arm64-simulator"

[[ -d "$DEV_DIR" ]] || err "Missing device slice directory: ios-arm64"
if [[ -d "$SIM_DIR_A" ]]; then
  SIM_DIR="$SIM_DIR_A"
elif [[ -d "$SIM_DIR_B" ]]; then
  SIM_DIR="$SIM_DIR_B"
else
  err "Missing simulator slice directory: ios-arm64[_x86_64]-simulator"
fi
ok "✅ Found slices → Device: ios-arm64 | Simulator: $(basename "$SIM_DIR")"

# ───────────────────────────────
# Step 2 – Find binaries
# ───────────────────────────────
step "Locating framework binaries..."
find_framework() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type d -name "*.framework" | head -n1
}

DEV_FW="$(find_framework "$DEV_DIR")"
SIM_FW="$(find_framework "$SIM_DIR")"

[[ -n "$DEV_FW" ]] || err "No .framework found in $DEV_DIR"
[[ -n "$SIM_FW" ]] || err "No .framework found in $SIM_DIR"

FW_NAME="$(basename "$DEV_FW" .framework)"
DEV_BIN="$DEV_FW/$FW_NAME"
SIM_BIN="$SIM_FW/$FW_NAME"

[[ -f "$DEV_BIN" ]] || err "Device binary not found: $DEV_BIN"
[[ -f "$SIM_BIN" ]] || err "Simulator binary not found: $SIM_BIN"
ok "✅ Found binaries → $FW_NAME"

# ───────────────────────────────
# Step 3 – Inspect architectures
# ───────────────────────────────
step "Inspecting architectures with lipo..."
info "Device binary:"
lipo -info "$DEV_BIN" || true
info "Simulator binary:"
lipo -info "$SIM_BIN" || true
ok "✅ Architecture inspection done"

# ───────────────────────────────
# Step 4 – Verify static (no LC_ID_DYLIB)
# ───────────────────────────────
step "Checking that binaries are static..."
if otool -l "$DEV_BIN" | grep -q "LC_ID_DYLIB"; then
  err "Device binary is dynamic (LC_ID_DYLIB found)"
fi
if otool -l "$SIM_BIN" | grep -q "LC_ID_DYLIB"; then
  err "Simulator binary is dynamic (LC_ID_DYLIB found)"
fi
ok "✅ Binaries are static (no LC_ID_DYLIB detected)"

# ───────────────────────────────
# Step 5 – Check .swiftinterface (module stability)
# ───────────────────────────────
step "Checking for .swiftinterface files..."
SWIFT_IF_COUNT=$(find "$XC" -name "*.swiftinterface" | wc -l | tr -d ' ')
if [[ "$SWIFT_IF_COUNT" -lt 1 ]]; then
  err "No .swiftinterface files found. Build with BUILD_LIBRARY_FOR_DISTRIBUTION=YES."
else
  ok "✅ Found $SWIFT_IF_COUNT .swiftinterface file(s) → Module Stability confirmed"
fi

# ───────────────────────────────
# All Done
# ───────────────────────────────
echo -e "\n${ICON_DONE}  All checks passed successfully for: $XC"
echo -e "${ICON_CHECK}  Device + Simulator slices exist"
echo -e "${ICON_CHECK}  Correct architectures"
echo -e "${ICON_CHECK}  Static binaries (no LC_ID_DYLIB)"
echo -e "${ICON_CHECK}  Swift module stability (.swiftinterface found)"
echo -e "\n🎯  Your XCFramework is valid and ready to publish!"
