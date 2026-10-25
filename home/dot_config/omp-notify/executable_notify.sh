#!/bin/sh
# Send a short notification to Telegram. Usage: notify.sh "message text"
# Credentials live in telegram.env next to this script (chmod 600):
#   TELEGRAM_BOT_TOKEN=123456:ABC...
#   TELEGRAM_CHAT_ID=123456789
#
# With AGENT_WORKFLOW_TELEGRAM_RECEIPT=1, a successful send prints one JSON line
# instead of "notify: sent", so the caller can bind a question to its message:
#   {"telegram":{"chat_id":-100123,"message_id":456,"bot_id":789}}
# taken from sendMessage's result.chat.id, result.message_id and result.from.id.
# Nothing else from Telegram's reply is printed or kept.
#
# Exit codes:
#   0   sent (with a valid receipt, when one was requested)
#   28  timed out: the message may or may not have arrived
#   3   sent, but the reply had no valid receipt: do not resend
#   1   not sent: missing credentials, or a receipt requested without jq
#   *   any other curl failure: not sent
set -eu
ENV_FILE="$(dirname "$0")/telegram.env"
# shellcheck source=/dev/null
. "$ENV_FILE"
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ] || {
  echo "notify: TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID not set in $ENV_FILE" >&2
  exit 1
}
MSG=${1:?usage: notify.sh "message"}

send() {
  curl -sf --max-time 15 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${MSG}" \
    --data-urlencode "parse_mode=HTML"
}

if [ "${AGENT_WORKFLOW_TELEGRAM_RECEIPT:-}" != 1 ]; then
  send >/dev/null
  echo "notify: sent"
  exit 0
fi

# Check before sending: a receipt we cannot parse must not cost a resend.
command -v jq >/dev/null 2>&1 || {
  echo "notify: receipt requested but jq is not installed; message not sent" >&2
  exit 1
}
reply=$(send)
receipt=$(printf '%s' "$reply" | jq -ce '
  def int: type == "number" and . == floor;
  select(.ok == true)
  | .result
  | {chat_id: .chat.id, message_id: .message_id, bot_id: .from.id}
  | select((.chat_id | int) and .chat_id != 0
      and (.message_id | int) and .message_id > 0
      and (.bot_id | int) and .bot_id > 0)
  | {telegram: .}' 2>/dev/null) || {
  echo "notify: sent, but Telegram's reply had no valid receipt; not resending" >&2
  exit 3
}
printf '%s\n' "$receipt"
