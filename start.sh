#!/usr/bin/env bash
# Asynchroniczny hotseat HotA - pobranie tury, instrukcja dla gracza, wysłanie tury.
set -uo pipefail
export LANG=C.UTF-8

cd "$(dirname "$(readlink -f "$0")")" || exit 1

hr() { printf '===================================================\n'; }

die() {
    printf '\n❌ BŁĄD: %s\n\n' "$1"
    read -rp "Naciśnij Enter, aby zamknąć..."
    exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "ten folder nie jest repozytorium gita. Wykonaj najpierw pierwszą konfigurację z README."

hr
echo "  1. POBIERANIE NAJNOWSZEGO ZAPISU Z GITHUBA..."
hr

git fetch origin main || die "nie udało się połączyć z GitHubem. Sprawdź internet i logowanie."

# --ff-only: jeśli lokalna historia się rozjechała, LEPIEJ stanąć niż nadpisać czyjąś turę.
if ! git merge --ff-only origin/main; then
    die "Twoja lokalna historia rozjechała się ze zdalną.
   Prawdopodobnie poprzedni push się nie udał, albo ktoś zagrał w tym samym czasie.
   NIE grajcie dalej - najpierw ustalcie z grupą, czyja tura jest właściwa."
fi

echo "✅ Zapisy zaktualizowane."
echo ""
hr
echo "  2. ZRÓB SWOJĄ TURĘ I ZAPISZ GRĘ"
hr
echo ""
echo "🎮 Odpal teraz grę (np. z Heroica), wczytaj zapis i wykonaj turę."
echo "💾 Zapisz grę pod ustaloną nazwą w TYM folderze."
echo ""
echo "👉 Naciśnij [Enter], gdy tura jest zapisana i gotowa do wysłania,"
echo "   lub [ESC] / [q], aby anulować i nic nie wysyłać."

IFS= read -rsn1 key
esc=$'\e'
if [[ "$key" == "$esc" || "$key" == "q" || "$key" == "Q" ]]; then
    echo ""
    echo "⏹️  Anulowano — nic nie zostało wysłane na GitHuba."
    exit 0
fi

echo ""
hr
echo "  3. WYSYŁANIE TWOJEJ TURY NA GITHUBA..."
hr

git add -A

if git diff --cached --quiet; then
    echo "ℹ️  Brak nowych zapisów - nie ma czego wysyłać."
    echo "   Jeśli grałeś, upewnij się, że zapisałeś grę w TYM folderze."
    read -rp "Naciśnij Enter, aby zakończyć..."
    exit 0
fi

echo "Pliki do wysłania:"
git diff --cached --name-only | sed 's/^/  • /'
echo ""

read -rp "Podaj krótki opis tury (lub 'q' aby anulować): " commit_msg
if [[ "$commit_msg" == "q" || "$commit_msg" == "Q" || "$commit_msg" == "anuluj" ]]; then
    echo "⏹️  Anulowano — commit i push nie zostały wykonane."
    exit 0
fi

if [ -z "${commit_msg// }" ]; then
    commit_msg="Wykonano turę - $(date '+%Y-%m-%d %H:%M')"
fi

git commit -m "$commit_msg" || die "commit się nie udał."

if ! git push origin main; then
    die "push odrzucony - ktoś wysłał turę w tym samym czasie.
   Twoja tura jest zapisana lokalnie (commit istnieje), ale NIE jest na GitHubie.
   Napisz na Discordzie przed jakąkolwiek dalszą akcją."
fi

echo ""
hr
echo "  ✅ SUKCES! Tura wysłana. Możesz zamknąć to okno."
hr
read -rp "Naciśnij Enter, aby zakończyć..."
