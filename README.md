# 🏰 HotA — asynchroniczny hotseat

Gramy w Heroes III (HotA) w hotseat, tylko że **nie musimy siedzieć razem przy jednym kompie**.
Sejw jeździ między nami przez GitHuba: pobierasz najnowszy stan gry, robisz swoją turę, wysyłasz.

W praktyce: **klikasz jeden skrypt i on robi całą robotę z gitem za Ciebie.** Nie musisz umieć
gita. Serio.

---

## 1. Pierwsza konfiguracja (robisz to RAZ)

### a) Zainstaluj Gita

- **Windows:** https://git-scm.com/download/win — instalator, wszystko domyślnie, Next → Next → Install.
- **Linux:** `sudo dnf install git` / `sudo apt install git`.

### b) Powiedz gitowi, kim jesteś

Twoje imię wyląduje w raporcie rozgrywki i na Discordzie, więc wpisz coś, po czym Cię poznamy.
Otwórz terminal (Windows: **Git Bash** z menu Start) i:

```bash
git config --global user.name "Twoj Nick"
git config --global user.email "twoj@email.pl"
```

### c) Zdobądź dostęp do repo

Repo jest **prywatne** (`git@github.com:4zriel/hota-priv.git`), więc:

1. Załóż konto na GitHubie (jeśli nie masz) i podaj mi swój login — dodam Cię do repo.
2. Zaloguj się lokalnie. Najprościej przez GitHub CLI (https://cli.github.com):

   ```bash
   gh auth login
   ```

   Wybierz `GitHub.com` → `SSH` → pozwól wygenerować klucz. Jak wolisz klasyczny klucz SSH i
   umiesz go wgrać do GitHuba, to też dobrze.

### d) Sklonuj repo **do katalogu gry**

To najważniejszy krok i najczęstsze miejsce, w którym można się wyłożyć. Skrypt startowy szuka
launchera gry **w swoim folderze i do 4 katalogów w górę**, więc repo musi wylądować gdzieś
wewnątrz katalogu HotA — najlepiej w podfolderze `Games`, tam gdzie normalnie siedzą sejwy.

```bash
cd "/sciezka/do/HoMM 3 Complete/Games"
git clone git@github.com:4zriel/hota-priv.git "Daggerwin valley"
```

Po sklonowaniu w folderze powinny być: `start.bat`, `start.sh`, `start.fish`, `README.md`
i sejw `Daggerwin.GM2`.

### e) Linux: potrzebujesz Wine

Skrypt odpala windowsowy launcher przez `wine` albo `portproton`. Jak nie masz żadnego:

```bash
sudo dnf install wine   # albo: sudo apt install wine
```

Windowsowcy: nic nie robicie, gra odpala się natywnie.

---

## 2. Jak zagrać turę

1. **Windows:** kliknij dwa razy `start.bat`.
   **Linux:** w terminalu `./start.sh` (albo `./start.fish`, jeśli używasz fisha).
2. Skrypt pobiera najnowszy sejw z GitHuba. Czekasz na `✅ Zapisy zaktualizowane.`
3. Odpala się launcher, a z niego Heroes. **Wczytaj grę i zrób swoją turę.**
4. ⚠️ **Zapisz grę pod ustaloną nazwą: `Daggerwin`** (czyli plik `Daggerwin.GM2`), w tym samym
   folderze co skrypt — nadpisujesz poprzedni zapis, to jest OK i tak ma być.
5. Wyjdź z Heroes i **wróć do okna skryptu**. Launcher potrafi zamknąć się od razu po odpaleniu
   gry, więc skrypt czeka na Twój Enter — wciśnij go dopiero, jak tura jest zrobiona i zapisana.
6. Skrypt pokaże listę plików do wysłania i poprosi o **krótki opis tury**
   (np. `Tura 12 - zdobyto zamek`). Ten opis widzą wszyscy na Discordzie i w `RAPORT.md`.
7. `✅ SUKCES! Tura wysłana.` — gotowe, zamykasz okno i piszesz na Discordzie, że następny gra.

> 💡 **Dlaczego jedna, sztywna nazwa sejwu?** Do repo wpuszczamy **tylko** plik `Daggerwin.GM*`.
> Zapiszesz pod inną nazwą — plik zostanie na Twoim dysku i nikt go nie zobaczy, a skrypt
> powie „brak nowych zapisów".

---

## 3. Zasady grupy (ważniejsze niż skrypty)

- 🔒 **Gra jedna osoba naraz.** Kolejność ustalamy na Discordzie.
- ⛔ **Nie zaczynaj tury, dopóki skrypt nie napisał `✅ Zapisy zaktualizowane.`** Jeśli krzyknął
  błędem — nie klikaj w Heroes, tylko napisz do nas.
- 🚨 **Jeśli push się nie uda — NIE GRAJ DALEJ i napisz na Discordzie.** Twoja tura jest wtedy
  zapisana lokalnie, ale nikt jej nie widzi. Kolejna tura zagrana „na ślepo" oznacza, że komuś
  przepadnie robota.
- 🧯 Nie ruszaj plików `start.*`, `.gitignore`, `.gitattributes` ani folderu `.github` —
  automat i tak zgłosi to na Discordzie jako ⚠️.

---

## 4. Gdy coś się wysypie

| Komunikat | Co to znaczy | Co zrobić |
|---|---|---|
| `ten folder nie jest repozytorium gita` | Odpalasz skrypt z kopii pliku, a nie z folderu sklonowanego repo | Wróć do kroku 1d — sklonuj repo i odpalaj `start.*` **stamtąd** |
| `nie udało się połączyć z GitHubem` | Brak neta albo nie jesteś zalogowany | Sprawdź internet, potem `gh auth login` |
| `Twoja lokalna historia rozjechała się ze zdalną` | Ktoś zagrał w tym samym czasie albo Twój poprzedni push padł | **Stop.** Nie graj, napisz na Discordzie — ustalamy, czyja tura jest właściwa |
| `nie znalazłem launchera gry` | Repo leży poza katalogiem gry | Przenieś folder repo do katalogu HotA (`.../HoMM 3 Complete/Games/...`) |
| `nie znaleziono Wine ani PortProton` | Linux bez Wine | `sudo dnf install wine` |
| `Brak nowych zapisów - nie ma czego wysyłać` | Zapisałeś pod inną nazwą albo w innym folderze | Zapisz jeszcze raz jako `Daggerwin`, w folderze repo |
| `push odrzucony` | Ktoś wysłał turę równolegle | Twoja tura jest w commicie lokalnie, **nic więcej nie rób** — napisz na Discordzie |

---

## 5. Dla hosta — setup nowej gry od zera

### Bootstrap

`bootstrap.fish` zamienia folder mapy w gotowe repo. **Nie commituje i nie pushuje** — kończy na
pokazaniu, co poszłoby do repo, żebyś mógł to obejrzeć przed wysłaniem.

```fish
./bootstrap.fish "/sciezka/do/HoMM 3 Complete/Games/Daggerwin valley" ~/Downloads/hota
```

Zanim odpalisz, ustaw na górze skryptu:

- `REMOTE` — adres repo (domyślnie `git@github.com:4zriel/hota-priv.git`),
- `SAVE_NAME` — nazwa wspólnego sejwu (domyślnie `Daggerwin.GM2`).

⚠️ `SAVE_NAME` musi zgadzać się **co do wielkości liter** z wzorcem `!Daggerwin.GM[0-9]`
w `.gitignore`. Zmieniasz jedno — zmień drugie, bo inaczej sejw nie wejdzie do repo.

Co robi skrypt: kasuje stare `.git` w folderze mapy → kopiuje skrypty, `.gitignore`,
`.gitattributes`, `README.md` oraz `.github/{workflows,scripts}` → `git init -b main` →
`git remote add origin` → `git add -A` → wypisuje listę plików i sumaryczny rozmiar.
Po drodze twardo sprawdza, czy do indeksu nie wpełzły autosejwy.

### Startowy sejw

Skrypt sam nie zgadnie, który zapis jest „ten właściwy" — skopiuj go ręcznie:

```fish
cp "/sciezka/do/mapy/411 - zrobiona tura komaca.GM2" "/sciezka/do/mapy/Daggerwin.GM2"
```

### Pierwszy commit

Jak lista z kroku 6 wygląda dobrze (żadnych `XYZ.GM4`, rozmiar poniżej ~2 MB):

```fish
cd "/sciezka/do/mapy"
git commit -m "init: czysty start - whitelist, workflow w .github, jeden sejw"
git push -u origin main
```

Coś nie tak? Nic nie jest scommitowane — wywal `.git` i powtórz.

### Discord

Powiadomienia jadą przez webhooka Discorda i **nie zadziałają, dopóki nie ustawisz sekretu.**

1. Discord: **Ustawienia kanału → Integracje → Webhooki → Nowy webhook → Kopiuj URL webhooka**.
2. GitHub: **Settings → Secrets and variables → Actions → New repository secret**,
   nazwa dokładnie `DISCORD_WEBHOOK`, wartość = skopiowany URL.

Sprawdzenie, czy działa — po następnej turze:

```bash
gh run list -R 4zriel/hota-priv -L 1
gh run view --log -R 4zriel/hota-priv | grep -i discord
```

Szukasz linii `✅ Powiadomienie wysłane na Discorda.`. Jak zamiast tego widzisz
`::warning::Brak sekretu DISCORD_WEBHOOK` — sekret nie jest ustawiony i workflow tylko
zapisuje raport, nic nie wysyła. Workflow celowo **nie wywala się** z tego powodu.

---

## 6. Jak to działa pod spodem

**`.gitignore` to whitelist, nie blacklist.** HotA nazywa autosejwy datą gry w świecie —
`111.GM4`, `235.GM4`, `[hotseat] 232.GM4` — więc nie da się ich odfiltrować po wzorcu nazwy.
Dlatego ignorujemy wszystko (`/*`) i jawnie wpuszczamy tylko to, co ma być w repo. Nowy, nieznany
plik jest domyślnie ignorowany. Katalog `.github/` musi być odignorowany jawnie — git nie wpuści
plików z wykluczonego katalogu, nawet z negacją na samym pliku.

**`.gitattributes`** oznacza sejwy jako `binary`. Bez tego git na Windowsie (`core.autocrlf=true`)
przepisałby bajty `0x0D0A` wewnątrz sejwu i gra by go nie wczytała. `RAPORT.md` dostaje
`merge=union`, żeby równoległe wpisy z CI scalały się bez konfliktu.

**`git merge --ff-only` zamiast `git pull`.** Jeśli historia się rozjechała, skrypt **staje** i
każe pytać grupy, zamiast po cichu mergować albo nadpisywać czyjąś turę.

**`.github/workflows/hota-turn.yml`** odpala się przy każdym pushu na `main` (poza zmianami
w samym `RAPORT.md`). `concurrency: hota-turn` serializuje przebiegi, więc dwa pushe pod rząd nie
biją się o raport, a commit bota ma `[skip ci]`, żeby nie zapętlić workflow.

**`.github/scripts/turn_report.py`** dopisuje wiersz do `RAPORT.md` (kto, kiedy, opis tury) i buduje
payload na Discorda. Dane o turze bierze z payloadu eventu, a nie z `git log -1` — w momencie
wysyłki ostatnim commitem jest już commit bota. Skrypt sprawdza też **wszystkie** pliki z pusha
i flaguje ⚠️ te spoza allowlisty: binarki gry (`.exe`, `.dll`, `.lod`…), skrypty i cokolwiek
w `.github/`. Mentiony w powiadomieniu są wyłączone, żeby `@everyone` w opisie tury nie zapingował
całego serwera.

Dwie rzeczy, które łatwo zepsuć przy grzebaniu w workflow:

- **`git add RAPORT.md` musi być przed sprawdzeniem zmian.** Przy pierwszym przebiegu RAPORT.md
  jest plikiem nieśledzonym, a `git diff` nieśledzonych nie widzi — workflow uznawał, że nie ma
  czego commitować, i raport nigdy nie powstawał w repo.
- **Krok Discorda ma `if: always()`.** Powiadomienie jest ważniejsze niż raport: nawet jeśli push
  `RAPORT.md` przegra wyścig i job skończy się błędem, gracze i tak dostaną info, że tura jest
  zrobiona.

---

## 7. Co gdzie leży

**W repo mapy (to, co widzą gracze):**

```
Daggerwin.GM2                    wspólny sejw - jedyny plik gry w repo
start.bat / start.sh / start.fish  skrypt tury (Windows / bash / fish)
README.md                        ten plik
RAPORT.md                        historia tur, generowana automatycznie
.gitignore / .gitattributes      whitelist plików + traktowanie sejwów jako binarek
.github/workflows/hota-turn.yml  automat raportu i powiadomień
.github/scripts/turn_report.py   logika raportu
```

**Tylko w folderze źródłowym (nie trafia do repo mapy):**

```
bootstrap.fish                   jednorazowy setup - narzędzie hosta
hota-turn.yml, turn_report.py    źródła kopiowane przez bootstrap do .github/
```
