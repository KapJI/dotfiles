#!/usr/bin/env bash
set -Eeuo pipefail

: "${CERT_DIR:=/etc/rsyslog/certs}"
: "${THRESHOLD_DAYS:=30}"
: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN missing}"
: "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID missing}"

secs=$(( THRESHOLD_DAYS * 24 * 3600 ))
now=$(date +%s)
exit_code=0

send_tg () {
  local text="$1"
  curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${text}" >/dev/null || true
}

shopt -s nullglob
mapfile -t certs < <(find "$CERT_DIR" -maxdepth 1 -type f \( -name '*.crt' -o -name '*.pem' \) | sort)
for f in "${certs[@]}"; do
  base=$(basename "$f")

  if ! enddate=$(openssl x509 -in "$f" -noout -enddate 2>/dev/null); then
    send_tg "⚠️ Failed to read certificate: ${base}"
    exit_code=1
    continue
  fi

  not_after=${enddate#notAfter=}
  # seconds until expiry (openssl -checkend returns 1 if expires within N seconds)
  if ! openssl x509 -in "$f" -noout -checkend "$secs" >/dev/null 2>&1; then
    end_epoch=$(date -d "$not_after" +%s)
    days_left=$(( (end_epoch - now) / 86400 ))
    subj=$(openssl x509 -in "$f" -noout -subject -nameopt RFC2253 2>/dev/null | sed 's/^subject=//')
    send_tg "🔔 Cert expiring in ~${days_left} day(s): ${base}
Subject: ${subj}
NotAfter: ${not_after}"
    exit_code=2
  fi
done

exit "$exit_code"
