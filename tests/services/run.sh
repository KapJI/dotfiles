#!/usr/bin/env sh
# Checks for bin/agent-workflow-services and the deprecated cgt-dispatcher-supervise
# forwarder, against a fake services.py in a throwaway HOME. Every run uses
# `env -i`, the bare environment a Coder startup_script provides, so the launcher
# must find python3 through the nix profile itself. Nothing real is started.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src="$here/../../home/bin"
fake=$(mktemp -d)
trap 'rm -rf "$fake"' EXIT

mkdir -p "$fake/bin"
chezmoi execute-template <"$src/executable_agent-workflow-services.tmpl" >"$fake/bin/agent-workflow-services"
cp "$src/executable_cgt-dispatcher-supervise" "$fake/bin/cgt-dispatcher-supervise"
chmod +x "$fake/bin/"*
# The launcher reads $HOME/.nix-profile through the nix profile script; point the
# fake HOME's at the real one so python3 resolves there and nowhere else.
ln -s "$(readlink -f "$HOME/.nix-profile")" "$fake/.nix-profile"
rel=$(sed -n 's|^services="\$HOME/\(.*\)"$|\1|p' "$fake/bin/agent-workflow-services")
mkdir -p "$fake/$(dirname "$rel")"
cat >"$fake/$rel" <<'PY'
import os, sys
with open(os.path.join(os.environ["HOME"], "calls"), "a") as f:
    f.write(sys.executable + "|" + " ".join(sys.argv[1:]) + "\n")
sys.exit(int(os.environ.get("FAKE_EXIT", "0")))
PY
reg="$fake/.local/state/agent-workflow/services/registry.json"
rc=0

# check NAME WANT_EXIT WANT_ARGS COMMAND...   (WANT_ARGS "-" = must not run)
check() {
    name=$1 want_exit=$2 want_args=$3
    shift 3
    rm -f "$fake/calls"
    env -i HOME="$fake" ${FAKE_EXIT:+FAKE_EXIT=$FAKE_EXIT} "$@" >/dev/null 2>"$fake/err"
    got=$?
    line=$(cat "$fake/calls" 2>/dev/null)
    args=${line#*|}
    [ -z "$line" ] && args=-
    if [ "$got" != "$want_exit" ] || [ "$args" != "$want_args" ]; then
        printf 'FAIL %s: exit %s (want %s), args <%s> (want <%s>), stderr <%s>\n' \
            "$name" "$got" "$want_exit" "$args" "$want_args" "$(cat "$fake/err")"
        rc=1
    fi
    case $line in
    "" | "$fake/.nix-profile/"*) ;;
    *) printf 'FAIL %s: python3 was %s, not the nix profile one\n' "$name" "${line%%|*}"; rc=1 ;;
    esac
}

aws="$fake/bin/agent-workflow-services"
check "adds the default registry"    0 "status --registry $reg"           "$aws" status
check "keeps args after it"          0 "stop --registry $reg --timeout 5" "$aws" stop --timeout 5
check "explicit --registry wins"     0 "status --registry /x"             "$aws" status --registry /x
check "explicit --registry= wins"    0 "status --registry=/x"             "$aws" status --registry=/x
check "no subcommand is usage"       2 "-"                                "$aws"
FAKE_EXIT=7 check "passes exit code" 7 "start --registry $reg"            "$aws" start
check "old name forwards to start"   0 "start --registry $reg"            "$fake/bin/cgt-dispatcher-supervise"

mv "$fake/$rel" "$fake/$rel.gone"
check "missing services.py"          1 "-"                                "$aws" status
grep -q "$rel" "$fake/err" || { echo "FAIL missing services.py: error does not name the path"; rc=1; }

[ "$rc" = 0 ] && echo "services: all checks passed"
exit "$rc"
