#!/usr/bin/env python
"""Paste clipboard text, or copy a clipboard image into an SSH session.

Mapped to shift+insert so Hyprland Super+V (stock Universal paste) stays a
key injection. Image transfer runs as a kitty background process; the
compositor never waits on scp.
"""

from __future__ import annotations

import json
import os
import tempfile
import time
from pathlib import Path

from kittens.tui.handler import result_handler

IMAGE_MIMES = (
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/webp",
    "image/gif",
)

EXT = {
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/webp": ".webp",
    "image/gif": ".gif",
}

SCP = "/usr/bin/scp"
NOTIFY = "/usr/bin/notify-send"


def main(args: list[str]) -> None:
    pass


def image_mime(types: tuple[str, ...] | list[str]) -> str | None:
    present = {t.strip() for t in types if t and t.strip()}
    if any(t.startswith("text/") for t in present):
        return None
    for mime in IMAGE_MIMES:
        if mime in present:
            return "image/jpeg" if mime == "image/jpg" else mime
    for t in present:
        if t.startswith("image/"):
            return t
    return None


def ssh_connection(window):
    from kittens.ssh.utils import get_connection_data

    candidates = []
    kitten_cmd = window.ssh_kitten_cmdline()
    if kitten_cmd:
        candidates.append(list(kitten_cmd))
    for proc in window.child.foreground_processes or []:
        cmd = list(proc.get("cmdline") or ())
        if cmd:
            candidates.append(cmd)
    cmd = list(window.child.cmdline or ())
    if cmd:
        candidates.append(cmd)
    for cmd in candidates:
        data = get_connection_data(cmd)
        if data and data.hostname:
            return data
    return None


def paste_text_clipboard(boss, window) -> None:
    if window.send_paste_event():
        return
    from kitty.clipboard import get_clipboard_string

    text = get_clipboard_string()
    if text:
        window.paste_with_actions(text)


def notify(boss, title: str, body: str) -> None:
    if os.path.exists(NOTIFY):
        boss.run_background_process([NOTIFY, "-a", "kitty", title, body])


def scp_cmd(conn, local: str, remote: str) -> list[str]:
    cmd = [SCP, "-o", "BatchMode=yes", "-o", "ConnectTimeout=8"]
    if conn.port:
        cmd += ["-P", str(conn.port)]
    if conn.identity_file:
        cmd += ["-i", conn.identity_file]
    cmd += [local, f"{conn.hostname}:{remote}"]
    return cmd


def paste_ssh_image(boss, window, target_window_id: int, mime: str, conn) -> None:
    blob = boss.clipboard.get_mime_data(mime)
    if not blob:
        paste_text_clipboard(boss, window)
        return

    ext = EXT.get(mime, ".png")
    local = Path(f"/tmp/clipboard-paste-{os.getuid()}{ext}")
    local.write_bytes(blob)
    remote = f"/tmp/clipboard-paste-{int(time.time())}{ext}"
    errf = tempfile.NamedTemporaryFile(prefix="kitty-scp-", suffix=".err", delete=False)
    err_path = errf.name

    def on_death(exit_status: int, err: Exception | None) -> None:
        try:
            local.unlink(missing_ok=True)
        except OSError:
            pass
        err_text = ""
        try:
            err_text = Path(err_path).read_text(errors="replace").strip()
        except OSError:
            pass
        try:
            os.unlink(err_path)
        except OSError:
            pass
        failed = err is not None
        if not failed:
            try:
                failed = os.waitstatus_to_exitcode(exit_status) != 0
            except ValueError:
                failed = True
        if failed:
            detail = str(err) if err is not None else (err_text or f"scp to {conn.hostname} failed")
            notify(boss, "Clipboard image paste failed", detail)
            return
        w = boss.window_id_map.get(target_window_id)
        if w is None or w.destroyed:
            return
        w.paste_text(json.dumps(remote))

    boss.run_background_process(
        scp_cmd(conn, str(local), remote),
        stderr=errf.fileno(),
        notify_on_death=on_death,
    )
    errf.close()


def _handle(target_window_id: int, boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None or window.destroyed:
        return
    if window.send_paste_event():
        return
    types = boss.clipboard.get_available_mime_types_for_paste()
    mime = image_mime(types)
    if mime:
        conn = ssh_connection(window)
        if conn is not None:
            paste_ssh_image(boss, window, target_window_id, mime, conn)
            return
    paste_text_clipboard(boss, window)


@result_handler(no_ui=True)
def handle_result(args, data, target_window_id, boss) -> None:
    try:
        _handle(target_window_id, boss)
    except Exception:
        try:
            boss.paste_from_clipboard()
        except Exception:
            pass
