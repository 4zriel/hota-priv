#!/usr/bin/env fish
# Asynchroniczny hotseat HotA - pobranie tury, uruchomienie gry, wysłanie tury.

cd (dirname (realpath (status --current-filename))); or exit 1

function hr
    echo "==================================================="
end

function die
    printf '\n❌ BŁĄD: %s\n\n' "$argv[1]"
    read -P "Naciśnij Enter, aby zamknąć... " _
    exit 1
end

function find_launcher
    set -l names "HD_Launcher.exe" "h3hota HD.exe" "h3hota.exe" "Heroes3 HD.exe"
    set -l dir "."
    for _ in 1 2 3 4
        for name in $names
            if test -f "$dir/$name"
                echo "$dir/$name"
                return 0
            end
        end
        set dir "$dir/.."
    end
    return 1
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
echo "  2. URUCHAMIANIE HEROES III (ZRÓB TURĘ I ZAPISZ)..."
hr

set -l launcher (find_launcher)
if test -z "$launcher"
    die "nie znalazłem launchera gry (HD_Launcher.exe) w tym ani w nadrzędnych folderach.
   Skrypt powinien leżeć w folderze z zapisami wewnątrz katalogu gry."
end

set -l runner
if type -q wine
    set runner wine
else if type -q portproton
    set runner portproton
else
    die "nie znaleziono Wine ani PortProton.
   Zainstaluj Wine (np. sudo apt install wine) i spróbuj ponownie."
end

echo "▶️  $runner $launcher"
if not $runner "$launcher"
    echo "⚠️  Launcher zwrócił błąd - sprawdź, czy gra faktycznie wystartowała."
end

echo ""
echo "⏸️  Launcher potrafi zamknąć się od razu po odpaleniu gry."
echo "   Zapisz grę pod ustaloną nazwą, wyjdź z Heroes III, i DOPIERO WTEDY wróć tutaj."
read -P "Naciśnij Enter, gdy tura jest zakończona i ZAPISANA... " _

echo ""
hr
echo "  3. WYSYŁANIE TWOJEJ TURY NA GITHUBA..."
hr

git add -A

if git diff --cached --quiet
    echo "ℹ️  Brak nowych zapisów - nie ma czego wysyłać."
    echo "   Jeśli grałeś, upewnij się, że zapisałeś grę w TYM folderze."
    read -P "Naciśnij Enter, aby zakończyć... " _
    exit 0
end

echo "Pliki do wysłania:"
git diff --cached --name-only | sed 's/^/  • /'
echo ""

read -P "Podaj krótki opis tury (np. Tura 12 - zdobyto zamek): " commit_msg
if test -z (string trim -- "$commit_msg")
    set commit_msg "Wykonano turę - "(date "+%Y-%m-%d %H:%M")
end

if not git commit -m "$commit_msg"
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
read -P "Naciśnij Enter, aby zakończyć... " _
