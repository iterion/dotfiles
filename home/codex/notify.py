#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import List, Optional


def _build_notification(notification: dict) -> tuple[str, str, str]:
    notification_type = notification.get("type")
    if notification_type != "agent-turn-complete":
        raise ValueError(f"not sending a push notification for: {notification_type}")

    assistant_message = notification.get("last-assistant-message") or ""
    input_messages = notification.get("input-messages", [])

    title = f"Codex: {assistant_message}".strip() or "Codex: Turn Complete!"
    message = " ".join(m for m in input_messages if isinstance(m, str)).strip()
    if not message:
        message = " "

    thread_id = str(notification.get("thread-id") or "")
    return title, message, thread_id


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
            check=True,
            capture_output=True,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

    return "CGSSessionScreenIsLocked = 1" in (result.stdout or "")


def _notify_with_terminal_notifier(title: str, message: str, thread_id: str) -> bool:
    terminal_notifier = shutil.which("terminal-notifier")
    if not terminal_notifier:
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
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as error:
        print(f"terminal-notifier failed: {error}", file=sys.stderr)
        return False
    except FileNotFoundError:
        return False

    return True


def _notify_with_pushover(title: str, message: str) -> bool:
    token = os.environ.get("CODEX_NOTIFY_PUSHOVER_TOKEN")
    user_key = os.environ.get("CODEX_NOTIFY_PUSHOVER_USER")
    if not token or not user_key:
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

    data = urllib.parse.urlencode(payload).encode("utf-8")
    request = urllib.request.Request(
        "https://api.pushover.net/1/messages.json", data=data, method="POST"
    )

    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return 200 <= response.getcode() < 300
    except (urllib.error.URLError, urllib.error.HTTPError) as error:
        print(f"Pushover failed: {error}", file=sys.stderr)
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
        return 0

    push_sent = False
    if _is_screen_locked():
        pushover_sent = _notify_with_pushover(title, message)
        ntfy_sent = _notify_with_ntfy(title, message)
        push_sent = pushover_sent or ntfy_sent

    if _notify_with_terminal_notifier(title, message, thread_id):
        return 0

    if push_sent:
        return 0

    print("No supported notification backend found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
