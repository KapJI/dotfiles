"""Real local go-grip integration, using owned temporary files and sockets."""

import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from urllib.parse import quote, urljoin
from urllib.request import ProxyHandler, build_opener


HELPER = Path(__file__).resolve().parents[2] / "home/dot_local/lib/mdpreview.py"
HTTP = build_opener(ProxyHandler({}))


class PreviewTest(unittest.TestCase):
    def test_shared_server_lifecycle_and_port_selection(self):
        self.assertIsNotNone(shutil.which("go-grip"), "sync the Nix profile before testing")
        with tempfile.TemporaryDirectory(prefix="mdpreview-test-") as scratch:
            root = Path(scratch)
            env = {**os.environ, "XDG_CACHE_HOME": str(root / "cache"),
                   "CODER_WORKSPACE_NAME": "fixture-workspace"}
            # Reserve two consecutive ports, then require the wrapper to skip
            # both without interfering with either listener.
            listeners = []
            for base in range(24000, 64000, 3):
                try:
                    for port in (base, base + 1, base + 2):
                        listener = socket.socket()
                        listeners.append(listener)
                        listener.bind(("127.0.0.1", port))
                        listener.listen()
                    listeners.pop().close()
                    break
                except OSError:
                    for listener in listeners:
                        listener.close()
                    listeners = []
            else:
                self.fail("no three consecutive test ports available")
            env["MDPREVIEW_PORT"] = str(base)

            def invoke(*args, **overrides):
                return subprocess.run([sys.executable, str(HELPER), *map(str, args)],
                                      env={**env, **overrides}, capture_output=True,
                                      text=True, timeout=20)

            def fetch(url):
                with HTTP.open(url, timeout=3) as response:
                    return response.read().decode()

            first = root / "one" / "docs" / "hello #world.md"
            second = root / "two" / "elsewhere.md"
            for path in (first, second):
                path.parent.mkdir(parents=True)
            subprocess.run(["git", "init", "-q", str(root / "one")], check=True)
            (root / "one/README.md").write_text("# Related page\n")
            first.write_text("# First preview\n\n![image](image.svg)\n\n[related](../README.md)\n")
            (first.parent / "image.svg").write_text('<svg xmlns="http://www.w3.org/2000/svg"/>')
            second.write_text("# Second preview\n")
            state_file = root / "cache/mdpreview/server.json"
            try:
                initial = invoke(first)
                self.assertEqual(initial.returncode, 0, initial.stderr)
                state = json.loads(state_file.read_text())
                port = base + 2
                self.assertEqual(state["port"], port)
                self.assertIn(f"coder port-forward fixture-workspace --tcp {port}:{port}", initial.stdout)
                first_url = next(line.removeprefix("Preview: ") for line in initial.stdout.splitlines()
                                 if line.startswith("Preview: "))
                self.assertIn(quote(first.name), first_url)
                self.assertIn(">First preview</h1>", fetch(first_url))
                self.assertIn("<svg ", fetch(first_url.rsplit("/", 1)[0] + "/image.svg"))
                self.assertIn(">Related page</h1>", fetch(urljoin(first_url, "../README.md")))
                # Wildcard binding (the unpatched go-grip 0.10.0 bug) prevents
                # this second loopback address from accepting the same port.
                if sys.platform.startswith("linux"):
                    with socket.socket() as other_interface:
                        other_interface.bind(("127.0.0.2", port))

                added = invoke(second)
                self.assertEqual(added.returncode, 0, added.stderr)
                self.assertEqual(json.loads(state_file.read_text()), state)
                second_url = next(line.removeprefix("Preview: ") for line in added.stdout.splitlines()
                                  if line.startswith("Preview: "))
                self.assertIn(">Second preview</h1>", fetch(second_url))
                self.assertIn("hello #world.md", fetch(f"http://127.0.0.1:{port}/"))
                self.assertIn("elsewhere.md", fetch(f"http://127.0.0.1:{port}/"))
                self.assertEqual(invoke().returncode, 0)

                marker = root / "cache/mdpreview/public/.changed"
                # Let registration settle before measuring the edit signal.
                time.sleep(0.7)
                before = marker.read_text() if marker.exists() else ""
                first.write_text("# Updated preview\n")
                deadline = time.monotonic() + 3
                while time.monotonic() < deadline:
                    if marker.exists() and marker.read_text() != before:
                        break
                    time.sleep(0.1)
                else:
                    self.fail("registered source edit did not signal go-grip's watcher")
                self.assertIn(">Updated preview</h1>", fetch(first_url))
                self.assertEqual(invoke(first).returncode, 0)
                files = json.loads((root / "cache/mdpreview/files.json").read_text())
                self.assertEqual(len(files), 2, "adding a file twice must not duplicate it")

                self.assertEqual(invoke("--stop").returncode, 0)
                with socket.socket() as freed:
                    freed.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                    freed.bind(("127.0.0.1", port))
                self.assertEqual(invoke().returncode, 0)
                self.assertNotEqual(json.loads(state_file.read_text())["token"], state["token"])
                self.assertIn("elsewhere.md", fetch(f"http://127.0.0.1:{port}/"))
                for listener in listeners:
                    self.assertEqual(listener.fileno() >= 0, True)
            finally:
                invoke("--stop")
                for listener in listeners:
                    listener.close()

    def test_invalid_input_does_not_start_a_server(self):
        with tempfile.TemporaryDirectory(prefix="mdpreview-invalid-") as scratch:
            env = {**os.environ, "XDG_CACHE_HOME": scratch}
            for args, overrides in ((["missing.md"], {}), ([], {"MDPREVIEW_PORT": "65536"}),
                                    ([], {"MDPREVIEW_PORT": "0"}), (["--stop", "x.md"], {})):
                with self.subTest(args=args, overrides=overrides):
                    result = subprocess.run([sys.executable, str(HELPER), *args],
                                            env={**env, **overrides}, capture_output=True, timeout=10)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse((Path(scratch) / "mdpreview/server.json").exists())


if __name__ == "__main__":
    unittest.main()
