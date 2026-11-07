# Telegram notifier transport

`home/dot_config/omp-notify/executable_notify.sh` installs as
`~/.config/omp-notify/notify.sh`. Ordinary callers pass a nonempty message argument;
the notifier sends it with `sendMessage` and `parse_mode=HTML`. Credentials remain
in the adjacent, host-owned `telegram.env`. No message argument means no send.

## Check transport support

Set `AGENT_WORKFLOW_TELEGRAM_CAPABILITIES=1`, pass no arguments, and leave both
`AGENT_WORKFLOW_TELEGRAM_RICH_FILE` and `AGENT_WORKFLOW_TELEGRAM_RECEIPT` **unset**.
The notifier returns this line without reading credentials or requiring curl,
Python or jq:

```json
{"version":1,"rich_file":true,"receipt":true,"max_file_bytes":32768}
```

Any other explicit capability value or combination exits 1 with
`notify: capability request rejected`. Empty variables count as present. Remove
the capability variable before an actual send. Probe only a known notifier
command; arbitrary programs may behave differently with no arguments.

## Opt into Rich HTML for one send

The caller creates a UTF-8 JSON file containing exactly one object:

```json
{"html":"<p>Question text</p>"}
```

Set `AGENT_WORKFLOW_TELEGRAM_RICH_FILE` to that path only for the send subprocess.
The file must be at most 32768 bytes, owned by the effective user, a regular file
with mode `0600`, and not a symlink. Its immediate parent must also be owned by
that user, have mode `0700`, and not be a symlink. Only the `html` key is allowed;
its value must be a nonempty string. Extra JSON documents, duplicate keys and
invalid UTF-8 or surrogate escapes are rejected. Whitespace inside HTML is kept.
The caller owns the file's contents and lifetime: keep them unchanged until the
subprocess finishes, then remove the scratch file.

Rich mode requires Python 3, jq and curl, all checked before network access. It
still requires a nonempty positional message argument for compatibility, but
ignores that argument's content. The notifier reads and validates the file once,
then sends that snapshot with the configured chat ID to `sendRichMessage` as
`rich_message`. The JSON body goes through stdin, not curl arguments. The payload
cannot override the chat, method, credentials or other API parameters. The
notifier does not validate HTML tags; escaping and supported markup belong to
the shared renderer. See Telegram's [Rich Message input contract](https://core.telegram.org/bots/api#inputrichmessage).

An absent rich-file variable preserves plain transport. A present but empty or
invalid value fails before sending; it never falls back to plain transport.
Shared workflow callers must clear inherited rich/capability variables for plain
sends and supply their own file for Rich sends. Callback identity checks, text
replies and answered/withdrawn edits belong to the shared workflow, not this
transport. Updating this script does not itself migrate workflow messages or
restart the listener; coordinate deployment with the shared workflow owner.

## Receipts and uncertain results

With `AGENT_WORKFLOW_TELEGRAM_RECEIPT=1`, success prints only:

```json
{"telegram":{"chat_id":-100123,"message_id":456,"bot_id":789}}
```

These integers come from the response's chat, message and sender IDs. Without a
receipt request, the success line remains `notify: sent`. Raw API bodies are
never printed or retained by the notifier. Rich validation and curl diagnostics
are suppressed; validation emits only the fixed preflight marker below. The
existing credential-bearing API URL still appears in curl's process arguments;
this is not protection against same-host process inspection.

| Exit | Meaning and caller action |
| --- | --- |
| `0` | Sent; bind only a valid requested receipt. Success without a valid receipt is unbound, not permission to resend. |
| `3` | The exchange completed but no valid requested receipt was available. Treat as sent/unbound; do not resend. |
| `28` | Curl timed out. Delivery is unknown; do not blindly resend. |
| `1` with exactly `notify: rich preflight rejected` on stderr | The notifier rejected Rich input, dependencies or credentials before a network attempt. |
| Any other nonzero result, including raw curl `1`, `52` and `56` without the marker | Preserved curl failure. Delivery is not proved absent; shared workflow must reconcile an unknown outcome before any retry. |

Invalid capability requests and legacy preflight failures also exit 1, with
their own diagnostics. They are not rich sends. The notifier makes one curl
attempt and never retries or sends a fallback. Rich mode disables curl's default
config-file loading so a user curl configuration cannot add retries or output
options to that path. The 15-second timeout is unchanged.

## Offline validation

Run `tests/notify/run.sh` from the repository. It uses copies of the notifier,
invented credentials, private temporary payloads and fake curl executables. The
tests verify default transport, Rich request/body and snapshot behavior, byte
limits, file types/modes, invalid input, capability isolation, dependencies,
receipts, call counts, raw failures and output redaction. They do not contact
Telegram. Python, jq and a POSIX shell are required for the test harness.
