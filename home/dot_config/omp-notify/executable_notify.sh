#!/bin/sh
# Send a short notification to Telegram. Usage: notify.sh "message text"
# Credentials live in telegram.env next to this script (chmod 600):
#   TELEGRAM_BOT_TOKEN=123456:ABC...
#   TELEGRAM_CHAT_ID=123456789
#
# With AGENT_WORKFLOW_TELEGRAM_RECEIPT=1, a successful send prints one JSON line
# instead of "notify: sent", so the caller can bind a question to its message:
#   {"telegram":{"chat_id":-100123,"message_id":456,"bot_id":789}}
# taken from the sent Message's result.chat.id, result.message_id and result.from.id.
# Nothing else from Telegram's reply is printed or kept.
#
# Exit codes:
#   0   sent (with a valid receipt, when one was requested)
#   28  timed out: the message may or may not have arrived
#   3   sent, but the reply had no valid receipt: do not resend
#   1   rich preflight marker proves no attempt; raw curl 1 does not
#   *   other curl failures propagate unchanged; delivery may be uncertain
# No automatic retries or plain fallback. See docs/telegram-notifier.md.
# Rich opt-in: AGENT_WORKFLOW_TELEGRAM_RICH_FILE points to a private JSON file.
# Capability-only: AGENT_WORKFLOW_TELEGRAM_CAPABILITIES=1, no arguments,
# and neither RICH_FILE nor RECEIPT variable present. No credentials are read.
set -eu

if [ "${AGENT_WORKFLOW_TELEGRAM_CAPABILITIES+x}" = x ]; then
  if [ "$AGENT_WORKFLOW_TELEGRAM_CAPABILITIES" != 1 ] || [ "$#" != 0 ] ||
    [ "${AGENT_WORKFLOW_TELEGRAM_RICH_FILE+x}" = x ] ||
    [ "${AGENT_WORKFLOW_TELEGRAM_RECEIPT+x}" = x ]; then
    echo "notify: capability request rejected" >&2
    exit 1
  fi
  echo '{"version":1,"rich_file":true,"receipt":true,"max_file_bytes":32768}'
  exit 0
fi

rich_preflight=0
if [ "${AGENT_WORKFLOW_TELEGRAM_RICH_FILE+x}" = x ]; then
  rich_preflight=1
  # This also catches source/command failures before network, without exposing
  # a credential file's contents or shell diagnostics. Clear only before send.
  trap 'if [ "$rich_preflight" = 1 ]; then
    echo "notify: rich preflight rejected" >&2
    exit 1
  fi' 0
  [ -n "${1:-}" ] && [ -n "$AGENT_WORKFLOW_TELEGRAM_RICH_FILE" ] || exit 1
  for dependency in python3 jq curl; do
    command -v "$dependency" >/dev/null 2>&1 || exit 1
  done
fi
case "$0" in
  */*) ENV_FILE="${0%/*}/telegram.env" ;;
  *) ENV_FILE="./telegram.env" ;;
esac
if [ "$rich_preflight" = 1 ]; then
  # shellcheck source=/dev/null
  . "$ENV_FILE" >/dev/null 2>&1
else
  # shellcheck source=/dev/null
  . "$ENV_FILE"
fi
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ] || {
  if [ "$rich_preflight" != 1 ]; then
    echo "notify: TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID not set in $ENV_FILE" >&2
  fi
  exit 1
}
MSG=${1:?usage: notify.sh "message"}

if [ "$rich_preflight" = 1 ]; then
  RICH_BODY=$(TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID" python3 - 2>/dev/null <<'PYTHON'
import json
import os
import stat


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key")
        result[key] = value
    return result


payload_path = os.path.abspath(os.environ["AGENT_WORKFLOW_TELEGRAM_RICH_FILE"])
parent, name = os.path.split(payload_path)
directory = os.open(parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
try:
    info = os.fstat(directory)
    if info.st_uid != os.geteuid() or stat.S_IMODE(info.st_mode) != 0o700:
        raise ValueError("private parent required")
    fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory)
    with os.fdopen(fd, "rb") as source:
        info = os.fstat(source.fileno())
        if (not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid()
                or stat.S_IMODE(info.st_mode) != 0o600 or info.st_size > 32768):
            raise ValueError("private bounded regular file required")
        raw = source.read(32769)
    if len(raw) > 32768:
        raise ValueError("oversize")
    rich = json.loads(raw.decode("utf-8"), object_pairs_hook=unique_object)
    if (not isinstance(rich, dict) or set(rich) != {"html"}
            or not isinstance(rich["html"], str) or not rich["html"]):
        raise ValueError("invalid rich object")
    rich["html"].encode("utf-8")  # Reject unpaired JSON surrogate escapes too.
    print(json.dumps({"chat_id": os.environ["TELEGRAM_CHAT_ID"], "rich_message": rich},
                     ensure_ascii=False, separators=(",", ":")))
finally:
    os.close(directory)
PYTHON
  ) || exit 1
fi

send() {
  if [ "${AGENT_WORKFLOW_TELEGRAM_RICH_FILE+x}" = x ]; then
    rich_preflight=0
    printf '%s' "$RICH_BODY" | curl -q -sf --max-time 15 \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendRichMessage" \
      --header 'Content-Type: application/json' --data-binary @- 2>/dev/null
    return
  fi
  curl -sf --max-time 15 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${MSG}" \
    --data-urlencode "parse_mode=HTML"
}

if [ "${AGENT_WORKFLOW_TELEGRAM_RECEIPT:-}" != 1 ]; then
  rich_preflight=0
  send >/dev/null
  echo "notify: sent"
  exit 0
fi

# Check before sending: a receipt we cannot parse must not cost a resend.
command -v jq >/dev/null 2>&1 || {
  echo "notify: receipt requested but jq is not installed; message not sent" >&2
  exit 1
}
rich_preflight=0
reply=$(send)
receipt=$(printf '%s' "$reply" | jq -cse '
  select(length == 1) | .[0]
  | def int: type == "number" and . == floor;
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
