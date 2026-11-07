"""Exercise the installed shell boundary with fake credentials and curl only."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "home/dot_config/omp-notify/executable_notify.sh"
RICH = "AGENT_WORKFLOW_TELEGRAM_RICH_FILE"
RECEIPT = "AGENT_WORKFLOW_TELEGRAM_RECEIPT"
CAPABILITIES = "AGENT_WORKFLOW_TELEGRAM_CAPABILITIES"
MARKER = "notify: rich preflight rejected\n"
CAPABILITY_JSON = '{"version":1,"rich_file":true,"receipt":true,"max_file_bytes":32768}\n'
OK = json.dumps({"ok": True, "result": {
    "chat": {"id": -700}, "message_id": 42, "from": {"id": 91},
    "text": "PRIVATE_RESPONSE",
}})
EXPECTED_RECEIPT = '{"telegram":{"chat_id":-700,"message_id":42,"bot_id":91}}\n'


class TransportTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="notify-contract-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("python3", "jq"):
            executable = shutil.which(name)
            if not executable:
                self.fail(f"test dependency missing: {name}")
            (self.bin / name).symlink_to(executable)
        self.script = self.root / "notify.sh"
        shutil.copyfile(SOURCE, self.script)
        self.creds = self.root / "telegram.env"
        self.creds.write_text(
            'printf read >> "$CREDENTIAL_READS"\n'
            'TELEGRAM_BOT_TOKEN=000:FAKE_SECRET_TOKEN\nTELEGRAM_CHAT_ID=-1001\n'
        )
        self.creds.chmod(0o600)
        self.payload_dir = self.root / "payload"
        self.payload_dir.mkdir(mode=0o700)
        self.payload = self.payload_dir / "rich.json"
        self.html = '<p>PRIVATE_PAYLOAD "quote" &amp; \\ slash\nsecond line ☃</p>'
        self.write_payload(json.dumps({"html": self.html}, ensure_ascii=False).encode())
        self.calls = self.root / "calls.jsonl"
        self.reads = self.root / "credential-reads"
        curl = self.bin / "curl"
        curl.write_text(f"#!{sys.executable}\n" + '''import json, os, pathlib, sys
args = sys.argv[1:]
if os.environ.get("REMOVE_PAYLOAD"):
    pathlib.Path(os.environ["AGENT_WORKFLOW_TELEGRAM_RICH_FILE"]).unlink()
body = sys.stdin.read() if "--data-binary" in args else ""
with open(os.environ["FAKE_CALLS"], "a") as log:
    log.write(json.dumps({"args": args, "body": body}) + "\\n")
print(os.environ.get("FAKE_STDERR", ""), end="", file=sys.stderr)
print(os.environ.get("FAKE_REPLY", ""), end="")
sys.exit(int(os.environ.get("FAKE_EXIT", "0")))
''')
        curl.chmod(0o700)
        self.env = {
            "PATH": str(self.bin), "FAKE_CALLS": str(self.calls),
            "CREDENTIAL_READS": str(self.reads), "FAKE_REPLY": OK,
            "LC_ALL": "C.UTF-8",
        }

    def write_payload(self, raw):
        self.payload.write_bytes(raw)
        self.payload.chmod(0o600)

    def run_notify(self, args=("LEGACY_IGNORED",), *, rich=True, receipt=True, **env):
        self.calls.unlink(missing_ok=True)
        variables = dict(self.env)
        if rich:
            variables[RICH] = str(self.payload)
        if receipt:
            variables[RECEIPT] = "1"
        variables.update(env)
        result = subprocess.run(
            ["/bin/sh", str(self.script), *args], env=variables,
            capture_output=True, text=True, timeout=5,
        )
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []
        for secret in ("PRIVATE_PAYLOAD", "PRIVATE_RESPONSE", "FAKE_SECRET_TOKEN"):
            self.assertNotIn(secret, result.stdout + result.stderr)
        return result, calls

    def assert_preflight(self, **kwargs):
        result, calls = self.run_notify(**kwargs)
        self.assertEqual((result.returncode, result.stdout, result.stderr, calls), (1, "", MARKER, []))

    def test_rich_body_and_receipt_use_validated_snapshot(self):
        result, calls = self.run_notify(REMOVE_PAYLOAD="1")
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, EXPECTED_RECEIPT, ""))
        self.assertEqual(len(calls), 1)
        self.assertFalse(self.payload.exists())
        request = calls[0]
        self.assertEqual(request["args"], [
            "-q", "-sf", "--max-time", "15",
            "https://api.telegram.org/bot000:FAKE_SECRET_TOKEN/sendRichMessage",
            "--header", "Content-Type: application/json", "--data-binary", "@-",
        ])
        self.assertEqual(json.loads(request["body"]), {
            "chat_id": "-1001", "rich_message": {"html": self.html},
        })
        self.assertNotIn("PRIVATE_PAYLOAD", " ".join(request["args"]))
        self.assertNotIn("LEGACY_IGNORED", request["body"])

    def test_plain_default_and_receipt_request_are_unchanged(self):
        for receipt in (False, True):
            with self.subTest(receipt=receipt):
                result, calls = self.run_notify(args=("hello <b>world</b>",), rich=False, receipt=receipt)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, EXPECTED_RECEIPT if receipt else "notify: sent\n")
                self.assertEqual(result.stderr, "")
                self.assertEqual(calls, [{"args": [
                    "-sf", "--max-time", "15",
                    "https://api.telegram.org/bot000:FAKE_SECRET_TOKEN/sendMessage",
                    "--data-urlencode", "chat_id=-1001",
                    "--data-urlencode", "text=hello <b>world</b>",
                    "--data-urlencode", "parse_mode=HTML",
                ], "body": ""}])

    def test_capability_needs_no_credentials_or_external_commands(self):
        self.creds.unlink()
        for path in self.bin.iterdir():
            path.unlink()
        result, calls = self.run_notify(args=(), rich=False, receipt=False, **{CAPABILITIES: "1"})
        self.assertEqual((result.returncode, result.stdout, result.stderr, calls), (0, CAPABILITY_JSON, "", []))
        self.assertFalse(self.reads.exists())

    def test_capability_invalid_combinations_never_read_credentials(self):
        cases = [
            (("message",), {CAPABILITIES: "1"}),
            ((), {CAPABILITIES: ""}), ((), {CAPABILITIES: "0"}),
            ((), {CAPABILITIES: "1", RICH: ""}),
            ((), {CAPABILITIES: "1", RECEIPT: ""}),
        ]
        for args, env in cases:
            with self.subTest(args=args, env=env):
                result, calls = self.run_notify(args=args, rich=False, receipt=False, **env)
                self.assertEqual((result.returncode, result.stdout, result.stderr, calls),
                                 (1, "", "notify: capability request rejected\n", []))
                self.assertFalse(self.reads.exists())

    def test_no_argument_is_never_a_send(self):
        for args in ((), ("",)):
            self.assert_preflight(args=args)
            result, calls = self.run_notify(args=args, rich=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(calls, [])

    def test_bad_opt_in_and_json_fail_before_network(self):
        self.assert_preflight(**{RICH: ""})
        self.assert_preflight(**{RICH: str(self.payload_dir / "missing")})
        invalid = [b"", b"PRIVATE_PAYLOAD", b"[]", b"null", b"{}",
                   b'{"html":""}', b'{"html":4}', b'{"html":false}',
                   b'{"html":"x","chat_id":3}', b'{"html":"x"} {}',
                   b'{"html":"x","html":"y"}', b'{"html":"\xff"}',
                   b'{"html":"\\ud800"}', b'\xef\xbb\xbf{"html":"x"}']
        for raw in invalid:
            with self.subTest(raw=raw):
                self.write_payload(raw)
                self.assert_preflight()

    def test_file_byte_limit_inclusive_and_utf8_not_characters(self):
        for length, code in ((32768, 0), (32769, 1)):
            with self.subTest(length=length):
                self.write_payload(b'{"html":"' + b'x' * (length - 11) + b'"}')
                self.assertEqual(self.payload.stat().st_size, length)
                result, calls = self.run_notify()
                self.assertEqual(result.returncode, code)
                self.assertEqual(len(calls), 1 if code == 0 else 0)
                self.assertEqual(result.stderr, "" if code == 0 else MARKER)
        self.write_payload(json.dumps({"html": "☃" * 12000}, ensure_ascii=False).encode())
        self.assert_preflight()

    def test_file_and_parent_modes(self):
        for mode in (0o644, 0o400, 0o660):
            with self.subTest(file_mode=mode):
                self.payload.chmod(mode)
                self.assert_preflight()
        self.payload.chmod(0o600)
        for mode in (0o755, 0o750, 0o1700):
            with self.subTest(parent_mode=mode):
                self.payload_dir.chmod(mode)
                self.assert_preflight()

    def test_symlink_directory_and_fifo_rejected_without_hanging(self):
        alias = self.payload_dir / "alias"
        alias.symlink_to(self.payload)
        self.assert_preflight(**{RICH: str(alias)})
        directory_alias = self.root / "linked-parent"
        directory_alias.symlink_to(self.payload_dir, target_is_directory=True)
        self.assert_preflight(**{RICH: str(directory_alias / self.payload.name)})
        self.assert_preflight(**{RICH: str(self.payload_dir)})
        fifo = self.payload_dir / "fifo"
        os.mkfifo(fifo, 0o600)
        self.assert_preflight(**{RICH: str(fifo)})

    def test_missing_dependencies_are_preflight(self):
        for name in ("python3", "jq", "curl"):
            with self.subTest(dependency=name):
                path = self.bin / name
                moved = self.root / ("saved-" + name)
                path.rename(moved)
                try:
                    self.assert_preflight()
                finally:
                    moved.rename(path)

    def test_missing_or_broken_credentials_are_preflight_without_leaks(self):
        self.creds.unlink()
        self.assert_preflight()
        for body in ("", "TELEGRAM_BOT_TOKEN=x\n", "echo PRIVATE_RESPONSE\nfalse\n",
                     'TELEGRAM_BOT_TOKEN="PRIVATE_RESPONSE\n'):
            with self.subTest(body=body):
                self.creds.write_text(body)
                self.assert_preflight()

    def test_raw_curl_codes_never_become_preflight_or_resends(self):
        for receipt in (False, True):
            for code in (1, 22, 28, 52, 56):
                with self.subTest(receipt=receipt, code=code):
                    result, calls = self.run_notify(receipt=receipt, FAKE_EXIT=str(code),
                                                    FAKE_STDERR="FAKE_SECRET_TOKEN PRIVATE_RESPONSE")
                    self.assertEqual((result.returncode, result.stdout, result.stderr), (code, "", ""))
                    self.assertEqual(len(calls), 1)
                    self.assertTrue(calls[0]["args"][4].endswith("/sendRichMessage"))

    def test_invalid_receipts_terminal_three_and_default_line(self):
        for reply in ("PRIVATE_RESPONSE", "{}", OK + "\n" + OK,
                      '{"ok":true,"result":{"chat":{"id":true},"message_id":2,"from":{"id":3}}}'):
            with self.subTest(reply=reply):
                result, calls = self.run_notify(FAKE_REPLY=reply)
                self.assertEqual((result.returncode, result.stdout), (3, ""))
                self.assertNotIn(MARKER.strip(), result.stderr)
                self.assertEqual(len(calls), 1)
        result, calls = self.run_notify(receipt=False)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "notify: sent\n", ""))
        self.assertEqual(len(calls), 1)


if __name__ == "__main__":
    unittest.main()
