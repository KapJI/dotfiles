#!/bin/sh
# Export Raspberry Pi throttle / under-voltage state for the textfile collector.
#
# node_exporter cannot see any of this: it lives in the VideoCore firmware and
# is only reachable via vcgencmd. Under-voltage from a marginal PSU or cable is
# the classic Pi failure -- it causes random misbehaviour that looks like
# anything but a power problem, and on a printer host that means ruined prints.
#
# `vcgencmd get_throttled` returns a bitmask. Bits 0-3 are live state; bits
# 16-19 latch on first occurrence and stay set until reboot.
set -eu

OUT=/var/lib/node_exporter/textfile/rpi_throttle.prom
TMP="$OUT.$$"

raw=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2) || raw=""
[ -n "$raw" ] || exit 0
val=$((raw))

bit() { echo $(( (val >> $1) & 1 )); }

{
    echo "# HELP rpi_throttle_bitmask Raw vcgencmd get_throttled bitmask."
    echo "# TYPE rpi_throttle_bitmask gauge"
    echo "rpi_throttle_bitmask $val"
    echo "# HELP rpi_throttle_flag Pi throttle state. window=now is live; window=since_boot latches until reboot."
    echo "# TYPE rpi_throttle_flag gauge"
    echo "rpi_throttle_flag{flag=\"under_voltage\",window=\"now\"} $(bit 0)"
    echo "rpi_throttle_flag{flag=\"freq_capped\",window=\"now\"} $(bit 1)"
    echo "rpi_throttle_flag{flag=\"throttled\",window=\"now\"} $(bit 2)"
    echo "rpi_throttle_flag{flag=\"soft_temp_limit\",window=\"now\"} $(bit 3)"
    echo "rpi_throttle_flag{flag=\"under_voltage\",window=\"since_boot\"} $(bit 16)"
    echo "rpi_throttle_flag{flag=\"freq_capped\",window=\"since_boot\"} $(bit 17)"
    echo "rpi_throttle_flag{flag=\"throttled\",window=\"since_boot\"} $(bit 18)"
    echo "rpi_throttle_flag{flag=\"soft_temp_limit\",window=\"since_boot\"} $(bit 19)"
} > "$TMP"

# Atomic: the collector must never read a half-written file.
mv -f "$TMP" "$OUT"
