@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title HotA - Asynchroniczny Hotseat
cd /d "%~dp0"

echo ===================================================
echo   1. POBIERANIE NAJNOWSZEGO ZAPISU Z GITHUBA...
echo ===================================================

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    set "ERR=ten folder nie jest repozytorium gita. Wykonaj najpierw pierwsza konfiguracje z README."
    goto :fail
)

git fetch origin main
if errorlevel 1 (
    set "ERR=nie udalo sie polaczyc z GitHubem. Sprawdz internet i logowanie."
    goto :fail
)

REM --ff-only: jesli lokalna historia sie rozjechala, LEPIEJ stanac niz nadpisac czyjas ture.
git merge --ff-only origin/main
if errorlevel 1 (
    set "ERR=Twoja lokalna historia rozjechala sie ze zdalna. Poprzedni push mogl sie nie udac, albo ktos zagral w tym samym czasie. NIE grajcie dalej - ustalcie na Discordzie, czyja tura jest wlasciwa."
    goto :fail
)

echo [OK] Zapisy zaktualizowane.
echo.
echo ===================================================
echo   2. URUCHAMIANIE HEROES III (ZROB TURE I ZAPISZ)...
echo ===================================================

REM Launcher lezy w katalogu gry, a skrypt w folderze zapisow - szukamy w gore drzewa.
set "LAUNCHER="
for %%D in ("." ".." "..\.." "..\..\..") do (
    for %%N in ("HD_Launcher.exe" "h3hota HD.exe" "h3hota.exe" "Heroes3 HD.exe") do (
        if not defined LAUNCHER if exist "%%~D\%%~N" set "LAUNCHER=%%~fD\%%~N"
    )
)

if not defined LAUNCHER (
    set "ERR=nie znalazlem launchera gry w tym ani w nadrzednych folderach. Skrypt powinien lezec w folderze z zapisami wewnatrz katalogu gry."
    goto :fail
)

echo Uruchamiam: !LAUNCHER!
start /wait "" "!LAUNCHER!"

echo.
echo [!] Launcher potrafi zamknac sie od razu po odpaleniu gry.
echo     Zapisz gre pod USTALONA nazwa, wyjdz z Heroes III, i DOPIERO WTEDY wroc tutaj.
pause

echo.
echo ===================================================
echo   3. WYSYLANIE TWOJEJ TURY NA GITHUBA...
echo ===================================================

git add -A

git diff --cached --quiet
if not errorlevel 1 (
    echo [i] Brak nowych zapisow - nie ma czego wysylac.
    echo     Jesli grales, upewnij sie, ze zapisales gre w TYM folderze.
    pause
    exit /b 0
)

echo Pliki do wyslania:
git diff --cached --name-only
echo.

REM --- Menu: kto dostaje powiadomienie na Discordzie ---------------------
REM Lista graczy siedzi w players.json (kolejnosc = kolejnosc tur).
set "TARGET=nastepny"
set /a PCOUNT=0

if exist "players.json" (
    for /f "usebackq tokens=1,* delims=:" %%A in (`findstr /c:"\"github\"" players.json`) do (
        set "V=%%B"
        set "V=!V:"=!"
        set "V=!V:,=!"
        set "V=!V: =!"
        if not "!V!"=="" (
            set /a PCOUNT+=1
            set "PLOGIN[!PCOUNT!]=!V!"
        )
    )
    set /a LCOUNT=0
    for /f "usebackq tokens=1,* delims=:" %%A in (`findstr /c:"\"discord\"" players.json`) do (
        set "V=%%B"
        set "V=!V:"=!"
        set "V=!V:,=!"
        set "V=!V: =!"
        set /a LCOUNT+=1
        set "PLABEL[!LCOUNT!]=!V!"
    )
)

if !PCOUNT! GTR 0 (
    set /a NOFIGHT=PCOUNT+1
    echo ===================================================
    echo   Z kim walczysz? ^(kogo powiadomic na Discordzie^)
    echo ===================================================
    for /l %%I in (1,1,!PCOUNT!) do (
        set "LAB=!PLABEL[%%I]!"
        if "!LAB!"=="" set "LAB=!PLOGIN[%%I]!"
        echo   %%I^) Walka z !LAB!
    )
    echo   !NOFIGHT!^) Brak walki, koniec tury ^(powiadomienie do nastepnego w kolejce^)
    echo.
    set "CH="
    set /p "CH=Wybierz [1-!NOFIGHT!], domyslnie !NOFIGHT!: "
    if not "!CH!"=="" (
        if !CH! GEQ 1 if !CH! LEQ !PCOUNT! (
            set "TARGET=!PLOGIN[%CH%]!"
            for %%C in (!CH!) do set "TARGET=!PLOGIN[%%C]!"
            echo [WALKA] Powiadomie: !TARGET!
        )
    )
    if "!TARGET!"=="nastepny" echo [OK] Powiadomie nastepnego gracza w kolejce.
    echo.
)

set "MSG="
set /p "MSG=Podaj krotki opis tury (np. Tura 12 - zdobyto zamek): "
if "!MSG!"=="" set "MSG=Wykonano ture - %DATE% %TIME:~0,5%"

git commit -m "!MSG!" -m "HotA-Cel: !TARGET!"
if errorlevel 1 (
    set "ERR=commit sie nie udal."
    goto :fail
)

git push origin main
if errorlevel 1 (
    set "ERR=push odrzucony - ktos wyslal ture w tym samym czasie. Twoja tura jest zapisana lokalnie, ale NIE jest na GitHubie. Napisz na Discordzie przed jakakolwiek dalsza akcja."
    goto :fail
)

echo.
echo ===================================================
echo   [OK] SUKCES! Tura wyslana. Mozesz zamknac to okno.
echo ===================================================
pause
exit /b 0

:fail
echo.
echo [BLAD] !ERR!
echo.
pause
exit /b 1
