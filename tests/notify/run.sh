#!/usr/bin/env sh
# Checks for home/dot_config/omp-notify/executable_notify.sh against a fake curl,
# so nothing reaches Telegram. Each case runs the script once and checks its
# stdout, exit code and how many sends it attempted.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
script="$here/../../home/dot_config/omp-notify/executable_notify.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/bin" "$work/notify"
cp "$script" "$work/notify/notify.sh"
printf 'TELEGRAM_BOT_TOKEN=000:fake-token\nTELEGRAM_CHAT_ID=-1001\n' >"$work/notify/telegram.env"
# The fake curl prints $FAKE_REPLY, or exits with $FAKE_EXIT, and counts calls.
cat >"$work/bin/curl" <<'CURL'
#!/bin/sh
echo call >>"$FAKE_CALLS"
[ -n "${FAKE_EXIT:-}" ] && exit "$FAKE_EXIT"
printf '%s' "$FAKE_REPLY"
CURL
chmod +x "$work/bin/curl"

ok='{"ok":true,"result":{"message_id":456,"from":{"id":789,"is_bot":true},"chat":{"id":-1001234567890},"text":"secret text"}}'
rc=0
# check NAME RECEIPT REPLY CURL_EXIT WANT_EXIT WANT_STDOUT
check() {
  : >"$work/calls"
  out=$(AGENT_WORKFLOW_TELEGRAM_RECEIPT="$2" FAKE_REPLY="$3" FAKE_EXIT="$4" \
    FAKE_CALLS="$work/calls" PATH="$work/bin:$PATH" \
    sh "$work/notify/notify.sh" "hello" 2>"$work/err")
  got=$?
  calls=$(wc -l <"$work/calls" | tr -d ' ')
  if [ "$got" != "$5" ] || [ "$out" != "$6" ] || [ "$calls" != 1 ]; then
    printf 'FAIL %s: exit %s (want %s), %s sends, stdout <%s> (want <%s>), stderr <%s>\n' \
      "$1" "$got" "$5" "$calls" "$out" "$6" "$(cat "$work/err")"
    rc=1
  fi
  if grep -q -e 'secret text' -e 'fake-token' "$work/err"; then
    printf 'FAIL %s: leaked reply text or token to stderr\n' "$1"
    rc=1
  fi
}

check "default keeps its line"     ""  "$ok" "" 0  "notify: sent"
check "receipt from reply"         1   "$ok" "" 0  '{"telegram":{"chat_id":-1001234567890,"message_id":456,"bot_id":789}}'
check "timeout stays 28"           1   ""    28 28 ""
check "default timeout stays 28"   ""  ""    28 28 ""
check "no from.id"                 1   '{"ok":true,"result":{"message_id":456,"chat":{"id":5}}}' "" 3 ""
check "message_id zero"            1   '{"ok":true,"result":{"message_id":0,"from":{"id":789},"chat":{"id":5}}}' "" 3 ""
check "chat_id zero"               1   '{"ok":true,"result":{"message_id":4,"from":{"id":789},"chat":{"id":0}}}' "" 3 ""
check "negative bot id"            1   '{"ok":true,"result":{"message_id":4,"from":{"id":-7},"chat":{"id":5}}}' "" 3 ""
check "fractional id"              1   '{"ok":true,"result":{"message_id":4.5,"from":{"id":7},"chat":{"id":5}}}' "" 3 ""
check "string id"                  1   '{"ok":true,"result":{"message_id":"4","from":{"id":7},"chat":{"id":5}}}' "" 3 ""
check "ok false"                   1   '{"ok":false,"result":{"message_id":4,"from":{"id":7},"chat":{"id":5}}}' "" 3 ""
check "not json"                   1   'secret text' "" 3 ""

[ "$rc" = 0 ] && echo "notify: all checks passed"
exit "$rc"
