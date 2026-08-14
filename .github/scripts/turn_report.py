#!/usr/bin/env python3
"""Dopisuje wpis do RAPORT.md i przygotowuje payload powiadomienia dla Discorda.

Dane o turze bierze z payloadu eventu (GITHUB_EVENT_PATH), a NIE z `git log -1`,
bo w momencie wysyłania powiadomienia ostatnim commitem jest już commit bota.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

REPORT_FILE = "RAPORT.md"
PAYLOAD_FILE = "discord-payload.json"
TIMEZONE = ZoneInfo("Europe/Warsaw")  # runner chodzi na UTC

REPORT_HEADER = (
    "# 🏰 Raport rozgrywki Heroes III: HotA\n"
    "\n"
    "| Data i czas | Gracz | Opis tury | Weryfikacja plików |\n"
    "|---|---|---|---|\n"
)

# Pliki narzędziowe, które MOGĄ się zmieniać bez podnoszenia flagi.
TOOLING_ALLOWLIST = {
    "start.bat",
    "start.sh",
    "start.fish",
    ".gitignore",
    ".gitattributes",
    "README.md",
    "RAPORT.md",
}

# Binarki gry i modów - ich podmiana to realna zmiana zasad rozgrywki.
BINARY_EXTS = {".exe", ".dll", ".lod", ".pac", ".snd", ".vid", ".dat", ".so"}

# Skrypty i konfiguracja automatyzacji poza allowlistą.
SCRIPT_EXTS = {".bat", ".cmd", ".sh", ".fish", ".ps1", ".py", ".yml", ".yaml"}


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], check=True, capture_output=True, text=True
    ).stdout


def commit_exists(sha: str) -> bool:
    if not sha or set(sha) == {"0"}:
        return False
    return (
        subprocess.run(
            ["git", "cat-file", "-e", f"{sha}^{{commit}}"],
            capture_output=True,
        ).returncode
        == 0
    )


def changed_files(before: str, head: str) -> list[str]:
    """Lista plików zmienionych w całym pushu, nie tylko w ostatnim commicie."""
    try:
        if commit_exists(before):
            out = git("diff", "--name-only", f"{before}..{head}")
        else:
            out = git("show", "--name-only", "--pretty=format:", head)
    except subprocess.CalledProcessError as exc:
        print(f"::warning::Nie udało się odczytać listy plików: {exc}", file=sys.stderr)
        return []
    return [line for line in out.splitlines() if line.strip()]


def flagged(files: list[str]) -> list[str]:
    hits = []
    for path in files:
        if path in TOOLING_ALLOWLIST:
            continue
        ext = os.path.splitext(path)[1].lower()
        if ext in BINARY_EXTS or ext in SCRIPT_EXTS or path.startswith(".github/"):
            hits.append(path)
    return hits


def md_cell(text: str) -> str:
    """Jedna linia, bez znaków rozwalających tabelę markdown."""
    first = text.strip().splitlines()[0] if text.strip() else "(brak opisu)"
    return first.replace("|", r"\|").replace("`", "'")[:200]


def main() -> int:
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    event = {}
    if event_path and os.path.exists(event_path):
        with open(event_path, encoding="utf-8") as fh:
            event = json.load(fh)

    head_commit = event.get("head_commit") or {}
    author = (head_commit.get("author") or {}).get("name") or "nieznany"
    message = head_commit.get("message") or "(brak opisu)"
    before = event.get("before") or ""
    head = event.get("after") or os.environ.get("GITHUB_SHA") or "HEAD"

    files = changed_files(before, head)
    hits = flagged(files)
    if hits:
        status = "⚠️ zmieniono pliki poza zapisami"
        print(f"::warning::Nietypowe pliki w tym pushu: {', '.join(hits)}")
    else:
        status = "✅ tylko zapisy gry"

    now = datetime.now(timezone.utc).astimezone(TIMEZONE).strftime("%Y-%m-%d %H:%M")

    if not os.path.exists(REPORT_FILE):
        with open(REPORT_FILE, "w", encoding="utf-8") as fh:
            fh.write(REPORT_HEADER)

    with open(REPORT_FILE, "a", encoding="utf-8") as fh:
        fh.write(f"| {now} | {md_cell(author)} | {md_cell(message)} | {status} |\n")

    lines = [
        "⚔️ **Zakończono nową turę w Heroes III!**",
        f"👤 **Gracz:** {author}",
        f"📝 **Opis:** {md_cell(message)}",
    ]
    if hits:
        shown = ", ".join(f"`{p}`" for p in hits[:5])
        lines.append(f"⚠️ **Uwaga – zmieniono też pliki:** {shown}")
    lines.append("")
    lines.append("➡️ **Kolejny gracz – odpal skrypt startowy i wykonaj swój ruch!**")

    payload = {
        "content": "\n".join(lines),
        # Bez tego commit message z @everyone pingowałby cały serwer.
        "allowed_mentions": {"parse": []},
    }
    with open(PAYLOAD_FILE, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
