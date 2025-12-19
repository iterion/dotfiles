#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from typing import List, Optional


PUSHOVER_TOKEN_PATH = os.path.expanduser("~/.config/codex/pushover-token")
PUSHOVER_USER_PATH = os.path.expanduser("~/.config/codex/pushover-user")
LOG_PATH = os.environ.get("CODEX_NOTIFY_LOG") or os.path.expanduser(
    "~/.config/codex/notify.log"
)


def _log(message: str) -> None:
    path = LOG_PATH
    if not path:
        return

    directory = os.path.dirname(path)
    try:
        if directory:
            os.makedirs(directory, exist_ok=True)
    except OSError:
        return

    timestamp = datetime.now().isoformat(timespec="seconds")
    try:
        with open(path, "a", encoding="utf-8") as handle:
            handle.write(f"{timestamp} {message}\n")
    except OSError:
        return


def _trimmed_join(parts: List[str]) -> str:
    seen = []
    for part in parts:
        cleaned = part.strip()
        if cleaned and cleaned not in seen:
            seen.append(cleaned)
    return " ".join(seen)


def _build_notification(notification: dict) -> tuple[str, str, str]:
    notification_type = notification.get("type")
    assistant_message = (notification.get("last-assistant-message") or "").strip()
    input_messages = [
        m for m in notification.get("input-messages", []) if isinstance(m, str)
    ]
    input_summary = _trimmed_join(input_messages)
    thread_id = str(notification.get("thread-id") or "")

    if notification_type == "agent-turn-complete":
        title = f"Codex: {assistant_message}".strip() or "Codex: Turn Complete!"
        message = input_summary or "Codex finished your request."
        return title, message, thread_id

    if notification_type == "approval-requested":
        default_title = "Codex: Approval Needed"
        possible_title_fields = [
            notification.get("title"),
            assistant_message and f"Codex: {assistant_message}",
        ]
        title = next(
            (field.strip() for field in possible_title_fields if isinstance(field, str) and field.strip()),
            default_title,
        )

        message_candidates: List[str] = []
        if assistant_message:
            message_candidates.append(assistant_message)

        for key in (
            "message",
            "summary",
            "prompt",
            "details",
            "approval_reason",
        ):
            value = notification.get(key)
            if isinstance(value, str):
                message_candidates.append(value)

        approvals = notification.get("approvals")
        if isinstance(approvals, dict):
            for key in ("message", "summary", "details"):
                value = approvals.get(key)
                if isinstance(value, str):
                    message_candidates.append(value)

        if input_summary:
            message_candidates.append(input_summary)

        message = _trimmed_join(message_candidates) or "Codex is waiting for your approval."
        return title, message, thread_id

    raise ValueError(f"not sending a push notification for: {notification_type}")


def _detect_bundle_id() -> Optional[str]:
    bundle_id = os.environ.get("CODEX_NOTIFY_BUNDLE_ID")
    if bundle_id:
        return bundle_id

    term_program = (os.environ.get("TERM_PROGRAM") or "").lower()
    if "ghostty" in term_program:
        return "com.mitchellh.ghostty"
    if "wezterm" in term_program:
        return "com.github.wez.wezterm"
    if "alacritty" in term_program:
        return "io.alacritty"
    if "iterm" in term_program:
        return "com.googlecode.iterm2"
    if "apple_terminal" in term_program or "terminal.app" in term_program:
        return "com.apple.Terminal"

    return None


def _is_screen_locked() -> bool:
    cgsession = (
        "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
    )

    if not os.path.exists(cgsession):
        return False

    try:
        result = subprocess.run(
            [cgsession, "-s"],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return False

    output = f"{result.stdout or ''}{result.stderr or ''}"
    if "CGSSessionScreenIsLocked = 1" in output:
        return True
    if "kCGSSessionScreenIsLocked = 1" in output:
        return True
    if "CGSSessionOnConsoleKey = 0" in output:
        return True
    return False


def _should_send_phone_notifications() -> bool:
    override = os.environ.get("CODEX_NOTIFY_FORCE_PUSH", "")
    if override.lower() in {"0", "false", "no"}:
        return False
    if override:
        return True
    return True


def _notify_with_terminal_notifier(title: str, message: str, thread_id: str) -> bool:
    terminal_notifier = shutil.which("terminal-notifier")
    if not terminal_notifier:
        _log("terminal-notifier not found on PATH")
        return False

    command: List[str] = [
        terminal_notifier,
        "-title",
        title,
        "-message",
        message,
        "-group",
        f"codex-{thread_id}",
        "-ignoreDnD",
    ]

    bundle_id = _detect_bundle_id()
    if bundle_id:
        command.extend(["-activate", bundle_id])

    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
        if result.stdout:
            snippet = result.stdout.strip()
            if len(snippet) > 200:
                snippet = f"{snippet[:200]}…"
            _log(f"terminal-notifier stdout: {snippet}")
        if result.stderr:
            snippet = result.stderr.strip()
            if len(snippet) > 200:
                snippet = f"{snippet[:200]}…"
            _log(f"terminal-notifier stderr: {snippet}")
        _log("Delivered notification via terminal-notifier")
    except subprocess.CalledProcessError as error:
        print(f"terminal-notifier failed: {error}", file=sys.stderr)
        _log(f"terminal-notifier failed: {error}")
        if error.stdout:
            snippet = error.stdout.strip()
            if len(snippet) > 200:
                snippet = f"{snippet[:200]}…"
            _log(f"terminal-notifier stdout (error): {snippet}")
        if error.stderr:
            snippet = error.stderr.strip()
            if len(snippet) > 200:
                snippet = f"{snippet[:200]}…"
            _log(f"terminal-notifier stderr (error): {snippet}")
        return False
    except FileNotFoundError:
        _log("terminal-notifier executable disappeared during run")
        return False

    return True


def _read_secret_file(path: Optional[str]) -> Optional[str]:
    if not path:
        return None
    expanded = os.path.expanduser(path)
    try:
        with open(expanded, "r", encoding="utf-8") as handle:
            value = handle.read().strip()
            if value:
                return value
    except OSError:
        return None
    return None


def _load_secret(env_var: str, default_path: Optional[str]) -> Optional[str]:
    direct = (os.environ.get(env_var) or "").strip()
    if direct:
        return direct

    file_var = os.environ.get(f"{env_var}_FILE")
    file_value = _read_secret_file(file_var)
    if file_value:
        return file_value

    return _read_secret_file(default_path)


def _notify_with_pushover(title: str, message: str) -> bool:
    token = _load_secret("CODEX_NOTIFY_PUSHOVER_TOKEN", PUSHOVER_TOKEN_PATH)
    user_key = _load_secret("CODEX_NOTIFY_PUSHOVER_USER", PUSHOVER_USER_PATH)
    if not token or not user_key:
        _log("Skipping Pushover: missing token or user key")
        return False

    payload = {
        "token": token,
        "user": user_key,
        "title": title,
        "message": message,
    }

    device = os.environ.get("CODEX_NOTIFY_PUSHOVER_DEVICE")
    if device:
        payload["device"] = device

    _log(
        "Attempting Pushover notification "
        f"(title='{title[:30]}', message_length={len(message)}, device={'yes' if device else 'no'})"
    )

    data = urllib.parse.urlencode(payload).encode("utf-8")
    request = urllib.request.Request(
        "https://api.pushover.net/1/messages.json", data=data, method="POST"
    )

    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            code = response.getcode()
            success = 200 <= code < 300
            if success:
                _log(f"Pushover notification succeeded with status {code}")
            else:
                _log(f"Pushover notification failed with status {code}")
            return success
    except urllib.error.HTTPError as error:
        body = ""
        try:
            raw_body = error.read()
            if raw_body:
                body = raw_body.decode("utf-8", "replace").strip()
        except OSError:
            body = ""

        if body:
            print(f"Pushover failed: {error} - {body}", file=sys.stderr)
            _log(f"Pushover failed: {error} - {body}")
        else:
            print(f"Pushover failed: {error}", file=sys.stderr)
            _log(f"Pushover failed: {error}")
        return False
    except urllib.error.URLError as error:
        print(f"Pushover failed: {error}", file=sys.stderr)
        _log(f"Pushover failed: {error}")
        return False


def _notify_with_ntfy(title: str, message: str) -> bool:
    topic = os.environ.get("CODEX_NOTIFY_NTFY_TOPIC")
    if not topic:
        return False

    server = os.environ.get("CODEX_NOTIFY_NTFY_SERVER", "https://ntfy.sh")
    url = f"{server.rstrip('/')}/{topic}"

    request = urllib.request.Request(
        url,
        data=message.encode("utf-8"),
        method="POST",
        headers={"Title": title},
    )

    token = os.environ.get("CODEX_NOTIFY_NTFY_TOKEN")
    if token:
        request.add_header("Authorization", f"Bearer {token}")

    priority = os.environ.get("CODEX_NOTIFY_NTFY_PRIORITY")
    if priority:
        request.add_header("Priority", priority)

    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return 200 <= response.getcode() < 400
    except (urllib.error.URLError, urllib.error.HTTPError) as error:
        print(f"ntfy failed: {error}", file=sys.stderr)
        _log(f"ntfy failed: {error}")
        return False


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: notify <NOTIFICATION_JSON>")
        return 1

    try:
        notification = json.loads(sys.argv[1])
    except json.JSONDecodeError:
        print("Invalid JSON payload", file=sys.stderr)
        return 1

    try:
        title, message, thread_id = _build_notification(notification)
    except ValueError as error:
        print(error)
        _log(f"Skipping notification: {error}")
        return 0

    _log(
        f"Processing notification type={notification.get('type')} thread_id={thread_id}"
    )

    push_sent = False
    if _should_send_phone_notifications():
        pushover_sent = _notify_with_pushover(title, message)
        ntfy_sent = _notify_with_ntfy(title, message)
        push_sent = pushover_sent or ntfy_sent
        _log(
            f"Push notification results pushover={pushover_sent} ntfy={ntfy_sent} push_sent={push_sent}"
        )

    if _notify_with_terminal_notifier(title, message, thread_id):
        _log("Notification delivered to desktop client")
        return 0

    if push_sent:
        _log("Notification delivered via phone-only backend")
        return 0

    print("No supported notification backend found", file=sys.stderr)
    _log("Notification delivery failed: no backend available")
    return 1


if __name__ == "__main__":
    sys.exit(main())
