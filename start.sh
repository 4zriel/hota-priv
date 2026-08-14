#!/usr/bin/env bash
# Asynchroniczny hotseat HotA - pobranie tury, uruchomienie gry, wysłanie tury.
set -uo pipefail
export LANG=C.UTF-8

cd "$(dirname "$(readlink -f "$0")")" || exit 1

hr() { printf '===================================================\n'; }

die() {
    printf '\n❌ BŁĄD: %s\n\n' "$1"
    read -rp "Naciśnij Enter, aby zamknąć..."
    exit 1
}

find_launcher() {
    local names=("HD_Launcher.exe" "h3hota HD.exe" "h3hota.exe" "Heroes3 HD.exe")
    local dir="."
    for _ in 1 2 3 4; do
        for name in "${names[@]}"; do
            if [ -f "$dir/$name" ]; then
                printf '%s/%s\n' "$dir" "$name"
                return 0
            fi
        done
        dir="$dir/.."
    done
    return 1
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
echo "  2. URUCHAMIANIE HEROES III (ZRÓB TURĘ I ZAPISZ)..."
hr

launcher="$(find_launcher)" \
    || die "nie znalazłem launchera gry (HD_Launcher.exe) w tym ani w nadrzędnych folderach.
   Skrypt powinien leżeć w folderze z zapisami wewnątrz katalogu gry."

if command -v wine >/dev/null 2>&1; then
    runner=(wine)
elif command -v portproton >/dev/null 2>&1; then
    runner=(portproton)
else
    die "nie znaleziono Wine ani PortProton.
   Zainstaluj Wine (np. sudo apt install wine) i spróbuj ponownie."
fi

echo "▶️  ${runner[0]} $launcher"
"${runner[@]}" "$launcher" || echo "⚠️  Launcher zwrócił błąd - sprawdź, czy gra faktycznie wystartowała."

echo ""
echo "⏸️  Launcher potrafi zamknąć się od razu po odpaleniu gry."
echo "   Zapisz grę pod ustaloną nazwą, wyjdź z Heroes III, i DOPIERO WTEDY wróć tutaj."
read -rp "Naciśnij Enter, gdy tura jest zakończona i ZAPISANA... "

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

read -rp "Podaj krótki opis tury (np. Tura 12 - zdobyto zamek): " commit_msg
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
