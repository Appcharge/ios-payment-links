#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Slack notifier with dual mode:
#
# NORMAL MODE (used by build.sh):
#   ./slack_notify.sh "<app>" "<env>" "<status>" "<summary>" "<notes>"
#   → Requires SLACK_WEBHOOK_URL
#
# TEST MODE:
#   ./slack_notify.sh --test "<app>" "<env>" "<status>" "<summary>" "<notes>"
#   → Does NOT send Slack message
#   → Prints formatted test output
# ============================================================

# Detect test mode
TEST_MODE=false
if [[ "${1:-}" == "--test" ]]; then
  TEST_MODE=true
  shift
fi

# Parse args
app_name="$1"
environment="$2"
status="$3"
summary="$4"
release_notes="$5"

# Emoji
status_emoji="❌ Failed"
[[ "$status" == "success" ]] && status_emoji="✅ Success"

date_str=$(date -u +"%Y-%m-%d %H:%M UTC")

message="🚀 *Publish Event Detected*\n\n"
message+="*SDK:* ${app_name}\n"
message+="*Environment:* ${environment}\n"
message+="*Status:* ${status_emoji}\n"
message+="*Date:* ${date_str}\n\n"
message+="*Summary:*\n${summary}\n\n"
message+="*Release Notes:*\n${release_notes}"

# TEST MODE → print only
if [[ "$TEST_MODE" == true ]]; then
  echo "====== Slack TEST MESSAGE ======"
  echo -e "$message"
  echo "====== END TEST (no Slack message sent) ======"
  exit 0
fi

# NORMAL MODE → send real message
: "${SLACK_WEBHOOK_URL:?SLACK_WEBHOOK_URL must be exported}"

curl -X POST \
  -H "Content-Type: application/json" \
  --data "{\"text\":\"$(echo "$message" | sed 's/\"/\\\"/g')\"}" \
  "$SLACK_WEBHOOK_URL"
