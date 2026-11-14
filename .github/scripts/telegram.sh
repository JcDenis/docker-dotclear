#!/usr/bin/env bash
# Send a Telegram message (HTML format).
#
# Usage: telegram.sh <text>
# Needs TELEGRAM_ID and TELEGRAM_TOKEN environment variables,
# nothing is sent without them. This script never fails.
set -uo pipefail

text="${1:?text is required}"

if [ -z "${TELEGRAM_ID:-}" ] || [ -z "${TELEGRAM_TOKEN:-}" ]; then
  echo "No Telegram settings, message not sent"
  exit 0
fi

curl -fsS -o /dev/null --retry 3 "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_ID}" \
  --data-urlencode "parse_mode=HTML" \
  --data-urlencode "disable_web_page_preview=true" \
  --data-urlencode "text=${text}" || echo "::warning::Telegram message not sent"
exit 0
