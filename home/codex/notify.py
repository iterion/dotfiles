#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys
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

    if _notify_with_terminal_notifier(title, message, thread_id):
        return 0

    print("No supported notification backend found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
