"""One on-demand go-grip server and index for explicitly registered Markdown files."""

import argparse
import errno
import fcntl
import hashlib
import html
from http.client import HTTPException
import json
import os
from pathlib import Path
import secrets
import shlex
import shutil
import signal
import socket
import subprocess
import sys
import time
from urllib.parse import quote
from urllib.request import ProxyHandler, build_opener


CACHE = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "mdpreview"
PUBLIC = CACHE / "public"
HTTP = build_opener(ProxyHandler({}))


def read(name, default=None):
    try:
        return json.loads((CACHE / name).read_text())
    except FileNotFoundError:
        return default


def write(name, value):
    temporary = CACHE / (name + ".tmp")
    temporary.write_text(json.dumps(value))
    temporary.replace(CACHE / name)


def busy(lock):
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return False
    except BlockingIOError:
        return True


def healthy(state):
    if not state:
        return False
    try:
        with HTTP.open(f"http://127.0.0.1:{state['port']}/.identity", timeout=0.3) as response:
            return response.read(128).decode() == state["token"]
    except (OSError, ValueError, HTTPException):
        return False


def available(start):
    for port in range(start, 65536):
        with socket.socket() as candidate:
            candidate.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                candidate.bind(("127.0.0.1", port))
            except OSError as error:
                if error.errno == errno.EADDRINUSE:
                    continue
                raise
            return port
    raise ValueError(f"no free port from {start} through 65535")


def fingerprints(files):
    result = []
    for filename in files:
        try:
            info = Path(filename).stat()
            result.append((filename, info.st_mtime_ns, info.st_size, info.st_ino))
        except FileNotFoundError:
            result.append((filename, None))
    return result


def supervise(lock_fd, start):
    # Inherit the exclusive server lock from the launcher. It is released by
    # the OS on exit; stale PIDs cannot cause us to reuse or stop another server.
    lock = os.fdopen(lock_fd)
    child = None

    def stop_signal(_signum, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop_signal)
    try:
        token = secrets.token_hex(24)
        (PUBLIC / ".identity").write_text(token)
        while True:
            port = available(start)
            state = {"port": port, "token": token}
            write("server.json", state)
            child = subprocess.Popen(
                ["go-grip", "--browser=false", "--host=127.0.0.1", f"--port={port}"],
                cwd=PUBLIC,
            )
            deadline = time.monotonic() + 10
            while child.poll() is None and time.monotonic() < deadline:
                if healthy(state):
                    break
                time.sleep(0.1)
            if child.poll() is None and healthy(state):
                break
            if child.poll() is not None and available(port) != port:
                # Another listener won between our bind probe and go-grip.
                start = port + 1
                continue
            raise RuntimeError("go-grip failed to start; see server.log")

        previous = fingerprints(read("files.json", {}))
        while child.poll() is None:
            if read("stop.json") == token:
                break
            current = fingerprints(read("files.json", {}))
            if current != previous:
                # go-grip's watcher does not follow source-directory symlinks.
                # Signal its root watcher when a registered source changes.
                (PUBLIC / ".changed").write_text(str(time.time_ns()))
                previous = current
            time.sleep(0.5)
    finally:
        if child is not None and child.poll() is None:
            child.terminate()
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()
        lock.close()


def register(paths):
    files = read("files.json", {})
    urls = []
    for filename in paths:
        path = Path(filename).resolve(strict=True)
        if not path.is_file() or path.suffix.lower() != ".md":
            raise ValueError(f"expected a Markdown file: {filename}")
        root = path.parent
        if shutil.which("git"):
            result = subprocess.run(
                ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
                capture_output=True, text=True,
            )
            if result.returncode == 0:
                root = Path(result.stdout.strip()).resolve()
        key = hashlib.sha256(str(root).encode()).hexdigest()[:20]
        link = PUBLIC / "roots" / key
        if not link.is_symlink():
            link.symlink_to(root, target_is_directory=True)
        if link.resolve() != root:
            raise ValueError("preview root collision")
        url = "/roots/" + key + "/" + quote(path.relative_to(root).as_posix())
        files[str(path)] = url
        urls.append(url)
    write("files.json", files)
    rows = "\n".join(
        f'<li><a href="{html.escape(url, quote=True)}">{html.escape(path)}</a></li>'
        for path, url in files.items()
    )
    index = PUBLIC / "index.html.tmp"
    index.write_text(
        '<!doctype html><meta charset="utf-8"><title>Markdown previews</title>'
        '<style>html{color-scheme:light dark}body{font:16px system-ui;'
        'max-width:70em;margin:3em auto;padding:0 1em}li{margin:1em 0;'
        'overflow-wrap:anywhere}</style><h1>Markdown previews</h1><ul>' + rows + '</ul>'
    )
    index.replace(PUBLIC / "index.html")
    return urls


def main():
    if len(sys.argv) == 4 and sys.argv[1] == "_serve":
        supervise(int(sys.argv[2]), int(sys.argv[3]))
        return
    parser = argparse.ArgumentParser(prog="mdpreview", description="Add Markdown files to one shared preview server.")
    parser.add_argument("files", nargs="*", metavar="FILE.md")
    parser.add_argument("--stop", action="store_true", help="stop the preview server; keep the index")
    args = parser.parse_args()
    if args.stop and args.files:
        parser.error("--stop does not accept files")
    start = os.environ.get("MDPREVIEW_PORT", "6419")
    if not start.isascii() or not start.isdecimal() or not 1 <= int(start) <= 65535:
        parser.error("MDPREVIEW_PORT must be an integer from 1 to 65535")
    os.umask(0o077)
    CACHE.mkdir(parents=True, exist_ok=True)
    (PUBLIC / "roots").mkdir(parents=True, exist_ok=True)
    with (CACHE / "registry.lock").open("a") as registry, (CACHE / "server.lock").open("a") as server:
        fcntl.flock(registry, fcntl.LOCK_EX)
        running = busy(server)
        if args.stop:
            if running:
                write("stop.json", read("server.json")["token"])
                deadline = time.monotonic() + 10
                while busy(server):
                    if time.monotonic() >= deadline:
                        raise RuntimeError("server did not stop; see server.log")
                    time.sleep(0.1)
            print("mdpreview: server stopped; registered files retained")
            return
        if not shutil.which("go-grip"):
            raise RuntimeError("go-grip is missing; sync the chezmoi Nix profile")
        urls = register(args.files)
        started = None
        if not running:
            (CACHE / "server.json").unlink(missing_ok=True)
            with (CACHE / "server.log").open("w") as log:
                started = subprocess.Popen(
                    [sys.executable, str(Path(__file__).resolve()), "_serve", str(server.fileno()), start],
                    # Own cwd: a caller's worktree may be deleted while we run.
                    cwd=CACHE, pass_fds=(server.fileno(),), start_new_session=True,
                    stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                )
        deadline = time.monotonic() + 15
        while not healthy(read("server.json")):
            if (started and started.poll() is not None) or time.monotonic() >= deadline:
                if started and started.poll() is None:
                    started.terminate()
                    started.wait(timeout=10)
                raise RuntimeError(f"preview server unavailable; see {CACHE / 'server.log'}")
            time.sleep(0.1)
        port = read("server.json")["port"]
        workspace = shlex.quote(os.environ.get("CODER_WORKSPACE_NAME") or "WORKSPACE")
        print(f"To forward port run: coder port-forward {workspace} --tcp {port}:{port}")
        print(f"Preview index: http://localhost:{port}/")
        for url in urls:
            print(f"Preview: http://localhost:{port}{url}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError) as error:
        sys.exit(f"mdpreview: {error}")
