#!/bin/sh
# Export klipper-backup freshness for the node_exporter textfile collector.
#
# The useful signal is NOT the wall-clock age of the last commit: this host is
# powered off between prints, so after a fortnight off any age-based rule fires
# the moment it boots, for a backup that was never needed.
#
# It is not the newest config mtime either. KlipperScreen rewrites
# KlipperScreen.conf on every boot with byte-identical content, so a
# newest_mtime-minus-last_commit drift climbs forever while git correctly has
# nothing to commit - an alert no backup run can ever clear. That is exactly
# what happened between 2026-09-04 and 2026-09-10.
#
# So compare CONTENT against the last backup commit and export how many config
# files differ. 0 means everything is backed up, however long ago that was and
# however many times something touched a file without changing it. Downtime
# stays invisible, which was the point of not using commit age.
#
# Read from HEAD, not the index: klipper-backup runs "git rm -r --cached ." mid
# backup, and this runs every 10 minutes, so the index is briefly empty.
set -eu

H="$HOME"
R="$H/config_backup"
# printer_data/config is a SYMLINK to /home/pi/klipper_config (legacy layout).
C=$(readlink -f "$H/printer_data/config")
PREFIX=${C#"$H"/}
OUT=/var/lib/node_exporter/textfile/klipper_backup.prom
TMP="$OUT.$$"

ts=$(git -C "$R" log -1 --format=%ct 2>/dev/null || echo 0)
unpushed=$(git -C "$R" rev-list --count '@{u}..HEAD' 2>/dev/null || echo -1)

differing() {
    # Backed up once, but changed or removed since.
    git -C "$R" ls-tree -r --name-only HEAD -- "$PREFIX" 2>/dev/null | while IFS= read -r f; do
        live="$H/$f"
        if [ ! -f "$live" ]; then
            echo "$f"
        elif ! git -C "$R" show "HEAD:$f" 2>/dev/null | cmp -s - "$live"; then
            echo "$f"
        fi
    done

    # Live now and eligible for backup, but never committed. Mirrors the tool:
    # nested symlinks are not followed (find needs -L to descend one), and the
    # .env exclude array plus its .gitignore are skipped.
    find "$C" -type f \
        -not -path '*/ShakeTune_results/*' \
        -not -path '*/auto_speed_graph/*' \
        -not -path '*/input_shaper_results/*' \
        -not -path '*/old/*' \
        -not -name '.env' -not -name 'secrets.conf' 2>/dev/null | while IFS= read -r live; do
        rel=${live#"$H"/}
        git -C "$R" cat-file -e "HEAD:$rel" 2>/dev/null || echo "$rel"
    done
}

dirty=$(differing | sort -u | wc -l)

{
    echo "# HELP klipper_backup_uncommitted_files Config files whose content differs from the last backup commit."
    echo "# TYPE klipper_backup_uncommitted_files gauge"
    echo "klipper_backup_uncommitted_files $dirty"
    echo "# HELP klipper_backup_last_commit_timestamp_seconds Unix time of the last config backup commit."
    echo "# TYPE klipper_backup_last_commit_timestamp_seconds gauge"
    echo "klipper_backup_last_commit_timestamp_seconds $ts"
    echo "# HELP klipper_backup_unpushed_commits Commits made locally but not pushed to the remote."
    echo "# TYPE klipper_backup_unpushed_commits gauge"
    echo "klipper_backup_unpushed_commits $unpushed"
} > "$TMP"
mv "$TMP" "$OUT"
