"""Codex PreToolUse guard (chezmoi-managed; registered by dot_codex/modify_hooks.json.tmpl) for AWF/ABD Codex Writers (user, AWF Q155 a, 2026-11-25).

Acts only when the Codex process was started with AWF_CODEX_WRITER=1; every other Codex session passes.
In a Writer session it denies pushes naming main or master, plain force pushes (--force-with-lease is
allowed), `+` refspecs and PR merges. It matches command text only: a push inside a script file is not seen.
"""
import json
import os
import re
import sys

if os.environ.get("AWF_CODEX_WRITER") != "1":
    sys.exit(0)
try:
    cmd = json.dumps(json.load(sys.stdin).get("tool_input", {}))
except ValueError:
    cmd = ""
# `git -C <dir> push` and other global options sit between git and push.
PUSH = r"\bgit\b[^\"]*?\bpush\b"
bad = (re.search(PUSH + r"[^\"]*\b(main|master)\b", cmd)
       or re.search(PUSH + r"[^\"]*(\s--force(?!-with-lease)\b|\s-f\b|\s\+\S)", cmd)
       or re.search(r"\bgh\s+pr\s+merge\b|/merge\b", cmd))
if bad:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", "permissionDecision": "deny",
        "permissionDecisionReason": "AWF Writer guard: no push to main/master, no plain force push, no merge"}}))
