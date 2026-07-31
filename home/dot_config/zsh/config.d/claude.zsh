# Claude Code helpers.

# cs — fuzzy-search Claude Code sessions across ALL projects and resume one.
#
# Reads ~/.claude/history.jsonl (Claude Code's machine-wide prompt index: one
# entry per prompt), dedupes to one row per session — labelled by the session's
# first prompt, newest first — lets you pick with fzf, then cd's into that
# project and resumes it. Any args seed the fzf query, e.g. `cs telegram bot`.
#
# Uses only the stable history.jsonl index; the per-session transcript format is
# internal to Claude Code and can change between versions. Needs jq (fzf for the
# interactive pick — without it, prints the table).
cs() {
  emulate -L zsh
  local hist="$HOME/.claude/history.jsonl"
  command -v jq &>/dev/null || { print -u2 "cs: needs jq"; return 1; }
  [[ -r $hist ]] || { print -u2 "cs: no $hist"; return 1; }

  local rows
  rows=$(jq -rs --arg home "$HOME" '
    [ .[] | select(.sessionId) ]
    | group_by(.sessionId)
    | map({
        id:    .[0].sessionId,
        proj:  .[0].project,
        first: ((.[0].display // "") | gsub("\\s+"; " ")),
        ts:    (map(.timestamp // 0) | max),
        n:     length,
      })
    | sort_by(-.ts)[]
    | [ (.ts / 1000 | localtime | strftime("%Y-%m-%d %H:%M")),
        (.n | tostring),
        (if (.proj | startswith($home)) then "~" + .proj[($home | length):] else .proj end),
        (.first[0:200]),
        .id,
        .proj ]
    | @tsv
  ' "$hist") || { print -u2 "cs: could not read $hist"; return 1; }
  [[ -n $rows ]] || { print -u2 "cs: no sessions found"; return 1; }

  if ! command -v fzf &>/dev/null; then
    print -r -- "$rows" | cut -f1-4
    print -u2 "cs: install fzf for an interactive pick"
    return 0
  fi

  local pick
  pick=$(print -r -- "$rows" | fzf \
    --delimiter='\t' --with-nth='1..4' --nth='3,4' \
    --layout=reverse --height='80%' --border \
    --query="$*" \
    --header='resume a Claude session  ·  date · #prompts · project · first prompt') || return
  [[ -n $pick ]] || return

  local id proj
  id=$(print -r -- "$pick" | cut -f5)
  proj=$(print -r -- "$pick" | cut -f6)
  [[ -n $id && -n $proj ]] || { print -u2 "cs: could not parse selection"; return 1; }
  [[ -d $proj ]] || { print -u2 "cs: project dir is gone: $proj"; return 1; }
  builtin cd -- "$proj" && claude --resume "$id"
}
