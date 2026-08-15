#!/usr/bin/env python3
"""Dopisuje wpis do RAPORT.md i przygotowuje payload powiadomienia dla Discorda.

Dane o turze bierze z payloadu eventu (GITHUB_EVENT_PATH), a NIE z `git log -1`,
bo w momencie wysyłania powiadomienia ostatnim commitem jest już commit bota.

Adresat powiadomienia:
  * jeśli w commicie jest trailer `HotA-Cel: <login-github>` - pingujemy tego gracza
    (walka - ruch należy do przeciwnika),
  * jeśli trailer to `HotA-Cel: nastepny` albo go brak - pingujemy kolejnego gracza
    z kolejki zdefiniowanej w players.json.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

REPORT_FILE = "RAPORT.md"
PAYLOAD_FILE = "discord-payload.json"
PLAYERS_FILE = "players.json"
TIMEZONE = ZoneInfo("Europe/Warsaw")  # runner chodzi na UTC

TARGET_PREFIX = "HotA-Cel:"
TARGET_NEXT = "nastepny"

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
    "players.json",
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


def load_players() -> list[dict]:
    if not os.path.exists(PLAYERS_FILE):
        print(f"::warning::Brak {PLAYERS_FILE} - powiadomienie bez wskazania gracza.")
        return []
    try:
        with open(PLAYERS_FILE, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"::warning::Nie udało się wczytać {PLAYERS_FILE}: {exc}")
        return []
    players = data.get("players") or []
    return [p for p in players if isinstance(p, dict)]


def split_target(message: str) -> tuple[str, str]:
    """Zwraca (czysty opis tury, token celu). Token '' = brak wskazania."""
    lines = message.splitlines()
    target = ""
    kept = []
    for line in lines:
        stripped = line.strip()
        if stripped.lower().startswith(TARGET_PREFIX.lower()):
            target = stripped[len(TARGET_PREFIX):].strip()
            continue
        kept.append(line)
    clean = "\n".join(kept).strip() or "(brak opisu)"
    return clean, target


def find_player(players: list[dict], login: str) -> int:
    if not login:
        return -1
    for idx, player in enumerate(players):
        if (player.get("github") or "").lower() == login.lower():
            return idx
    return -1


def mention(player: dict) -> tuple[str, str | None]:
    """Zwraca (tekst mentiona, discord_id lub None)."""
    discord_id = (player.get("discord_id") or "").strip()
    if discord_id.isdigit():
        return f"<@{discord_id}>", discord_id
    handle = (player.get("discord") or "").strip()
    if handle:
        return handle, None
    return player.get("name") or "nieznany gracz", None


def main() -> int:
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    event = {}
    if event_path and os.path.exists(event_path):
        with open(event_path, encoding="utf-8") as fh:
            event = json.load(fh)

    head_commit = event.get("head_commit") or {}
    author = (head_commit.get("author") or {}).get("name") or "nieznany"
    author_login = (
        (head_commit.get("author") or {}).get("username")
        or (event.get("pusher") or {}).get("name")
        or ""
    )
    raw_message = head_commit.get("message") or "(brak opisu)"
    message, target_token = split_target(raw_message)

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

    # --- kogo pingujemy ---------------------------------------------------
    players = load_players()
    target_player: dict | None = None
    is_fight = False

    if players:
        if target_token and target_token.lower() != TARGET_NEXT:
            idx = find_player(players, target_token)
            if idx >= 0:
                target_player = players[idx]
                is_fight = True
            else:
                print(f"::warning::Nieznany cel '{target_token}' - biorę następnego w kolejce.")
        if target_player is None:
            cur = find_player(players, author_login)
            if cur >= 0:
                target_player = players[(cur + 1) % len(players)]
            else:
                print(
                    f"::warning::Autor '{author_login}' nie jest w players.json - "
                    "nie wiem, kto jest następny."
                )

    lines = [
        "⚔️ **Zakończono nową turę w Heroes III!**",
        f"👤 **Gracz:** {author}",
        f"📝 **Opis:** {md_cell(message)}",
    ]
    if hits:
        shown = ", ".join(f"`{p}`" for p in hits[:5])
        lines.append(f"⚠️ **Uwaga – zmieniono też pliki:** {shown}")
    lines.append("")

    mention_ids: list[str] = []
    if target_player is not None:
        text, discord_id = mention(target_player)
        if discord_id:
            mention_ids.append(discord_id)
        if is_fight:
            lines.append(
                f"⚔️ **{text} – masz walkę! Odpal skrypt startowy i rozegraj bitwę.**"
            )
        else:
            lines.append(
                f"➡️ **{text} – Twoja kolej! Odpal skrypt startowy i wykonaj swój ruch.**"
            )
    else:
        lines.append("➡️ **Kolejny gracz – odpal skrypt startowy i wykonaj swój ruch!**")

    payload = {
        "content": "\n".join(lines),
        # Bez tego commit message z @everyone pingowałby cały serwer.
        # Pingujemy WYŁĄCZNIE wskazanego gracza (jeśli ma ustawione discord_id).
        "allowed_mentions": {"parse": [], "users": mention_ids},
    }
    with open(PAYLOAD_FILE, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
