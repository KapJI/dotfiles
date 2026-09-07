# Claude Code helpers.

# cs — fuzzy-search Claude Code sessions across ALL projects and resume one.
#
# Claude Code's own `--resume` picker only sees the current project. cs spans
# every project: it reads ~/.claude/history.jsonl (the machine-wide prompt
# index, one entry per prompt), drops the sessions that can no longer be
# resumed, lets you pick with fzf, then cd's into that project and resumes it.
# Any args seed the fzf query, e.g. `cs telegram bot`.
#
# Rows are labelled with the title Claude Code generated for the session (the
# `ai-title` record its own picker shows), falling back to the first prompt
# that is not a slash command. Labelling by the literal first prompt does not
# work: it is very often `/model` or `/usage`, which says nothing about what
# the session was, and leaves that session unmatchable by any query.
#
# The query matches the project, the title and *every* prompt in the session,
# so a topic first raised on prompt 40 still finds it. The list itself stays a
# list of sessions: the prompts are matched but never shown there, and the
# preview pane is where you see which ones hit.
#
# history.jsonl is never trimmed, but Claude Code prunes transcripts on its
# cleanup schedule, so much of the index points at conversations `claude
# --resume` rejects with "No conversation found". Only sessions whose
# transcript is still on disk are listed.
#
# history.jsonl is the stable index; transcripts are read only for liveness
# (the UUID filename) and titles, and both degrade quietly if that internal
# format shifts — an unreadable title falls back to a prompt, and no readable
# transcript at all falls back to listing the whole index. Needs jq (fzf for
# the interactive pick — without it, prints the table).
cs() {
  emulate -L zsh
  local hist="$HOME/.claude/history.jsonl"
  local projects="$HOME/.claude/projects"
  command -v jq &>/dev/null || { print -u2 "cs: needs jq"; return 1; }
  [[ -r $hist ]] || { print -u2 "cs: no $hist"; return 1; }

  # Transcripts sit one level down, `<project>/<session-uuid>.jsonl`; the depth
  # keeps subagent transcripts out. Keying liveness on the UUID avoids
  # reimplementing Claude Code's project-directory name mangling.
  #
  # Only the tail of each transcript is scanned for the title. Claude Code
  # rewrites `ai-title` as a session drifts and the newest one lands within 30
  # lines of EOF, so this window reproduces a full scan exactly here while
  # costing what a full scan cannot: `grep` is /usr/bin/grep on macOS, and BSD
  # grep takes 2.3s over a 240 MB store against 0.25s for the window, which
  # stays flat as the store grows. A title outside the window is not fatal —
  # that session falls back to its first real prompt.
  local -a transcripts live
  local titles=''
  transcripts=( $projects/*/*.jsonl(N.) )
  live=( ${transcripts:t:r} )
  (( $#transcripts )) && titles=$(tail -n 200 $transcripts 2>/dev/null | grep '"type":"ai-title"')

  local rows
  rows=$(jq -rs --arg home "$HOME" --arg live "${(F)live}" --arg titles "$titles" '
    # Whitespace folding without a regex: jq gsub is Oniguruma-backed and
    # costs 0.5s over these ~5.5k prompts against 0.15s for the splits.
    def clean:
      (. // "")
      | split("\n") | join(" ") | split("\t") | join(" ") | split("\r") | join(" ")
      | split(" ") | map(select(length > 0)) | join(" ");

    ( $live | split("\n") | map(select(length > 0)) | INDEX(.) ) as $alive
    | ( $titles | split("\n")
        | map(select(length > 0) | (try fromjson catch empty))
        | map(select(.sessionId and (.aiTitle | strings) and (.aiTitle | length > 0)))
        | INDEX(.sessionId) | map_values(.aiTitle) ) as $title
    | [ .[] | select(.sessionId) ]
    | group_by(.sessionId)
    | map(
        .[0].sessionId as $id
        | [ .[] | .display | clean | select(length > 0) ] as $prompts
        | {
            id:      $id,
            proj:    (.[0].project // ""),
            ts:      (map(.timestamp // 0) | max),
            n:       length,
            label:   ( $title[$id]
                       // ($prompts | map(select(startswith("/") | not)) | .[0])
                       // $prompts[0]
                       // "(no prompts)" ),
            prompts: $prompts,
          } )
    | map(select(($alive | length) == 0 or ($alive[.id] != null)))
    | sort_by(-.ts)[]
    | .label as $label
    | [ (.ts / 1000 | localtime | strftime("%Y-%m-%d %H:%M")),
        (.n | tostring),
        (if (.proj | startswith($home)) then "~" + .proj[($home | length):] else .proj end),
        ($label[0:120]),
        ([ .prompts[] | select(. != $label) ] | join("  ·  ")),
        .id,
        .proj ]
    | @tsv
  ' "$hist") || { print -u2 "cs: could not read $hist"; return 1; }
  [[ -n $rows ]] || { print -u2 "cs: no resumable sessions found"; return 1; }

  if ! command -v fzf &>/dev/null; then
    print -r -- "$rows" | cut -f1-4
    print -u2 "cs: install fzf for an interactive pick"
    return 0
  fi

  # fzf can only search text it displays, and a whole conversation has no place
  # on a row. So the prompt trail rides along as a field that is never shown,
  # and the matching moves out of the picker: --disabled turns fzf's own search
  # off, and every keystroke reloads the list from a nested `fzf --filter` that
  # matches the full row, trail included. Same flags either side, so ranking
  # and --exact behave exactly as they would with fzf searching for itself — it
  # just never has to display what it matched on. Placeholders read the
  # original line rather than the displayed one, so field 5 still reaches the
  # preview and the id and path still reach the resume.
  #
  # --exact because a row carries a whole conversation: fuzzy matching finds a
  # query's letters scattered somewhere in tens of kB of prompts and keeps
  # nearly every session (74 rows -> 61 for "transfer to spouse", against 4
  # exact). A leading ' still makes a single term fuzzy.
  #
  # `|| true` because --filter exits 1 when nothing matches, and fzf leaves the
  # previous results on screen when a reload command fails — a query that
  # matches nothing would look like a query that matched the last thing.
  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/cs-rows.XXXXXX") \
    || { print -u2 "cs: could not create a temp file"; return 1; }
  trap "rm -f -- ${(q)tmp}" EXIT
  print -r -- "$rows" > $tmp
  local search="fzf --delimiter='\t' --with-nth='1..5' --nth='3..5' --exact --filter {q} < ${(q)tmp} || true"

  # The row shows a session; the preview shows why it matched. It splits that
  # same hidden field 5 back into one line per prompt and greps it for the
  # query, so you get every mention, each numbered with its position in the
  # session, with the term highlighted — `3:` and `410:` tell you it came up at
  # the start and again 400 prompts later. No query, or a query fzf matched by
  # scattered terms rather than as a phrase, falls back to the whole
  # conversation, so an empty pane never means "no information". It reads the
  # row rather than re-reading history.jsonl, so the preview can only ever show
  # text the query actually matched against.
  local preview='p=$(printf "%s\n" {5} | awk "{gsub(/  ·  /, \"\n\"); print}")
printf "%s\n" "$p" | grep -in --color=always -F -e {q} || printf "%s\n" "$p"'

  local -a rowlist=( ${(f)rows} )
  local pick
  pick=$(fzf \
    --delimiter='\t' --with-nth='1..4' \
    --disabled --query="$*" \
    --bind="start:reload($search)" --bind="change:reload($search)" \
    --layout=reverse --height='80%' --border \
    --preview="$preview" --preview-window='down,45%,wrap,border-top' \
    --preview-label=' prompts ' \
    --header="resume a Claude session  ·  date · #prompts · project · title  ·  ${#rowlist} sessions" \
    < /dev/null) || return
  [[ -n $pick ]] || return

  local id proj
  id=$(print -r -- "$pick" | cut -f6)
  proj=$(print -r -- "$pick" | cut -f7)
  [[ -n $id && -n $proj ]] || { print -u2 "cs: could not parse selection"; return 1; }
  [[ -d $proj ]] || { print -u2 "cs: project dir is gone: $proj"; return 1; }
  builtin cd -- "$proj" && claude --resume "$id"
}
