#!/usr/bin/env fish
# Asynchroniczny hotseat HotA - pobranie tury, instrukcja dla gracza, wysłanie tury.

cd (dirname (realpath (status --current-filename))); or exit 1

function hr
    echo "==================================================="
end

function die
    printf '\n❌ BŁĄD: %s\n\n' "$argv[1]"
    read -P "Naciśnij Enter, aby zamknąć... "
    exit 1
end

if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
    die "ten folder nie jest repozytorium gita. Wykonaj najpierw pierwszą konfigurację z README."
end

hr
echo "  1. POBIERANIE NAJNOWSZEGO ZAPISU Z GITHUBA..."
hr

if not git fetch origin main
    die "nie udało się połączyć z GitHubem. Sprawdź internet i logowanie."
end

# --ff-only: jeśli lokalna historia się rozjechała, LEPIEJ stanąć niż nadpisać czyjąś turę.
if not git merge --ff-only origin/main
    die "Twoja lokalna historia rozjechała się ze zdalną.
   Prawdopodobnie poprzedni push się nie udał, albo ktoś zagrał w tym samym czasie.
   NIE grajcie dalej - najpierw ustalcie z grupą, czyja tura jest właściwa."
end

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

read -s -n 1 -l key
set -l esc (printf "\x1b")
if test "$key" = "$esc" -o "$key" = "q" -o "$key" = "Q"
    echo ""
    echo "⏹️  Anulowano — nic nie zostało wysłane na GitHuba."
    exit 0
end

echo ""
hr
echo "  3. WYSYŁANIE TWOJEJ TURY NA GITHUBA..."
hr

git add -A

if git diff --cached --quiet
    echo "ℹ️  Brak nowych zapisów - nie ma czego wysyłać."
    echo "   Jeśli grałeś, upewnij się, że zapisałeś grę w TYM folderze."
    read -P "Naciśnij Enter, aby zakończyć... "
    exit 0
end

echo "Pliki do wysłania:"
git diff --cached --name-only | sed 's/^/  • /'
echo ""

# --- Menu: kto dostaje powiadomienie na Discordzie --------------------------
set -l players_file "players.json"
set -l logins
set -l labels

if test -f "$players_file"
    set logins (string replace -r '.*"([^"]*)"$' '$1' \
        (grep -o '"github"[[:space:]]*:[[:space:]]*"[^"]*"' "$players_file"))
    set labels (string replace -r '.*"([^"]*)"$' '$1' \
        (grep -o '"discord"[[:space:]]*:[[:space:]]*"[^"]*"' "$players_file"))
end

set -l target "nastepny"
set -l n (count $logins)

if test $n -gt 0
    hr
    echo "  Z kim walczysz? (kogo powiadomić na Discordzie)"
    hr
    for i in (seq $n)
        set -l lab $labels[$i]
        test -n "$lab"; or set lab $logins[$i]
        printf '  %d) Walka z %s\n' $i "$lab"
    end
    printf '  %d) Brak walki, koniec tury (powiadomienie do następnego w kolejce)\n' (math $n + 1)
    echo ""
    read -P "Wybierz [1-"(math $n + 1)"], domyślnie "(math $n + 1)": " -l choice
    if string match -qr '^[0-9]+$' -- "$choice"; and test "$choice" -ge 1 -a "$choice" -le $n
        set target $logins[$choice]
        set -l lab $labels[$choice]
        test -n "$lab"; or set lab $target
        echo "⚔️  Powiadomię: $lab"
    else
        echo "➡️  Powiadomię następnego gracza w kolejce."
    end
    echo ""
end

read -P "Podaj krótki opis tury (np. Tura 12 - zdobyto zamek) lub 'q' aby anulować: " commit_msg
if test "$commit_msg" = "q" -o "$commit_msg" = "Q" -o "$commit_msg" = "anuluj"
    echo "⏹️  Anulowano — commit i push nie zostały wykonane."
    exit 0
end

if test -z (string trim -- "$commit_msg")
    set commit_msg "Wykonano turę - "(date "+%Y-%m-%d %H:%M")
end

if not git commit -m "$commit_msg" -m "HotA-Cel: $target"
    die "commit się nie udał."
end

if not git push origin main
    die "push odrzucony - ktoś wysłał turę w tym samym czasie.
   Twoja tura jest zapisana lokalnie (commit istnieje), ale NIE jest na GitHubie.
   Napisz na Discordzie przed jakąkolwiek dalszą akcją."
end

echo ""
hr
echo "  ✅ SUKCES! Tura wysłana. Możesz zamknąć to okno."
hr
read -P "Naciśnij Enter, aby zakończyć... "
