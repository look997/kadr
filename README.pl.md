# Kadr

[English](README.md) | Polski

Kadr to aplikacja GTK4/libadwaita do kadrowania wielu obrazów. Ustaw jeden kadr dla wszystkich albo osobny dla wybranych plików.

Interfejs jest dostępny po polsku i angielsku; język zależy od ustawień systemu.

![Główne okno Kadr](screenshot.png)

![Przeglądanie wczytanych obrazów](demo.gif)

![Dialog zapisu](screenshot-dialog.png)

## Funkcje

- **Jeden kadr dla całej listy.** Ustaw kadr raz, a zostanie zastosowany do każdego wczytanego obrazu.
- **Kadr indywidualny (`#N`).** Wybrane obrazy dostają wspólny, osobny kadr; pozostałe zachowują kadr ogólny.
- **Przeglądanie bez utraty zaznaczenia.** Ctrl/Shift+klik zaznacza miniatury. Strzałki, kółko nad panelem miniatur i zwykły klik działają dalej bez kasowania zaznaczenia. Zmienia je tylko Ctrl/Shift, a czyści `Esc` albo *Odznacz*.
- **Skalowanie kadru do obrazu.** Obrazy o tych samych proporcjach co wzorzec dostają proporcjonalnie przeskalowany kadr (plakietka `%` na miniaturze) — przydatne dla tych samych zdjęć w różnych rozdzielczościach.
- **Zapis jako kopie albo w miejscu.** *Zapisz jako* tworzy przycięte kopie obok oryginałów lub w wybranym folderze. *Zastąp oryginalne* nadpisuje pliki dopiero po utworzeniu kopii; *Cofnij* przywraca oryginały także po restarcie programu.
- **Schemat nazwy.** Domyślnie `[nazwa]_%Y%m%d-%H%M%S`; dostępne są też `[nazwa]`, `[nr]` i kody daty `strftime`. Dialog podgląda nazwy, a całe polecenie kadrowania i zapisu można skopiować do schowka.
- **Formaty obsługiwane przez system.** Kadr czyta formaty obsługiwane przez GdkPixbuf, m.in. JPEG, PNG, WebP, TIFF, AVIF i HEIF. Format bez obsługi zapisu jest zapisywany jako PNG obok oryginału.
- **Wklejanie i upuszczanie.** Ctrl+V wkleja bitmapę albo pliki ze schowka; można też przeciągnąć obrazy na okno albo kliknąć puste pole, by wybrać pliki.
- **Elastyczny panel miniatur.** Panel można umieścić na dole, po prawej albo ukryć. Uchwyt zmienia jego wysokość (liczbę wierszy miniatur) lub szerokość.
- **Przywracanie sesji.** Kadry, lista obrazów, schemat nazw, pozycja panelu i rozmiar okna są zapamiętywane i przywracane po restarcie.
- **Precyzyjna edycja.** Proporcje kadru, powiększanie i przesuwanie obrazu, lupa oraz cofanie zmian kadru.

## Demo w przeglądarce

[Otwórz eksperymentalne demo HTML](https://look997.github.io/kadr/kadr.html). To osobna, robocza wersja, może zawierać błędy i nie zastępuje aplikacji desktopowej.
Język demo zależy od języka przeglądarki; można go wymusić przez `?lang=en` lub `?lang=pl`. Demo można zainstalować jako PWA i uruchamiać offline po pierwszym wczytaniu.

## Instalacja

### Arch Linux (AUR)

```sh
yay -S kadr
```

[Pakiet AUR](https://aur.archlinux.org/packages/kadr)

### Z repozytorium

```sh
git clone https://github.com/look997/kadr.git
cd kadr
sudo install -Dm755 kadr /usr/bin/kadr
sudo install -Dm644 org.kadr.kadr.desktop /usr/share/applications/org.kadr.kadr.desktop
sudo install -Dm644 org.kadr.kadr.svg /usr/share/icons/hicolor/scalable/apps/org.kadr.kadr.svg
sudo install -Dm644 org.kadr.kadr.metainfo.xml /usr/share/metainfo/org.kadr.kadr.metainfo.xml
```

Bez uprawnień roota skopiuj `kadr` do `~/bin/` albo `~/.local/bin/` i dodaj ten katalog do `PATH`.

### Zależności

Wymagane są GTK4, libadwaita, PyGObject, Pycairo i GdkPixbuf. W Arch Linux odpowiadają im pakiety `gtk4`, `libadwaita`, `python-gobject`, `python-cairo` i `gdk-pixbuf2`.
Dostępne formaty obrazów zależą od zainstalowanych modułów GdkPixbuf, takich jak `librsvg` i `libheif`.

Po zainstalowaniu zależności uruchom `./kadr`. Do codziennych lokalnych testów desktopowych służy `./install-local.sh --restart`: instaluje kopię w `~/.local/bin/kadr` i restartuje aplikację bez uprawnień roota.

### Flatpak

Szablon manifestu Flatpaka znajduje się w [`flatpak/org.kadr.kadr.yml.in`](flatpak/org.kadr.kadr.yml.in). Używa identyfikatora `org.kadr.kadr` i środowiska GNOME, więc GTK4 i libadwaita pochodzą ze wspólnego runtime'u, a nie z prywatnego zestawu bibliotek. `./release.sh <wersja>` wstawia dokładny adres i sumę archiwum wydania, tworząc gotowy manifest `dist/org.kadr.kadr.yml`.

Po utworzeniu wydania zbuduj i zainstaluj je lokalnie (wymagane Flatpak, `flatpak-builder` oraz GNOME 51 SDK/runtime):

```sh
flatpak install --user flathub org.gnome.Platform//51 org.gnome.Sdk//51
flatpak-builder --user --install --force-clean build-dir dist/org.kadr.kadr.yml
flatpak run org.kadr.kadr
```

Sandbox używa portali GTK do wyboru plików i nie żąda szerokiego dostępu do systemu plików hosta. Wygenerowany manifest jest przypięty do deterministycznego archiwum `dist/kadr-<wersja>.tar.gz`; skrypt wydania wysyła oba pliki jako assety GitHub Release. Zbuduj i przetestuj manifest, a następnie skorzystaj z aktualnej procedury zgłaszania nowej aplikacji przez Flathub. Po akceptacji repozytorium aplikacji będzie się nazywać `flathub/org.kadr.kadr`; każde kolejne wydanie wymaga zgłoszenia zaktualizowanego, przypiętego manifestu do tego repozytorium. Flathub weryfikuje ID aplikacji i manifest w ramach zgłoszenia.

## Użycie

```sh
kadr                    # puste okno
kadr fotki/*.jpg        # od razu otwórz pasujące pliki
kadr ~/Obrazy           # otwórz folder
```

1. **Otwórz obrazy** przyciskiem, przeciągając pliki na okno albo przez Ctrl+V.
2. **Przeciągnij ramkę** na obrazie. Współrzędne X, Y, szerokość i wysokość można też wpisać liczbowo.
3. **Przeglądaj:** kółko nad obrazem zmienia powiększenie, a nad panelem miniatur — bieżący obraz.
4. **Zapisz:**
   - *Zapisz jako* tworzy przycięte kopie według schematu nazwy. Środkowy przycisk myszy na przycisku zapisuje od razu ostatnim schematem, bez otwierania dialogu.
   - *Zastąp oryginalne* nadpisuje pliki po utworzeniu ich kopii; *Cofnij* przywraca oryginały.

### Skróty klawiaturowe i mysz

| Klawisz / gest | Działanie |
|---|---|
| `Ctrl+V` | wklej obrazy lub pliki ze schowka |
| `Ctrl+A` | zaznacz wszystkie miniatury |
| `Esc` | wyczyść zaznaczenie |
| `←` `→` | poprzedni / następny obraz (przytrzymanie przewija) |
| `↑` `↓` `+` `−` | zmień powiększenie |
| kółko nad obrazem | zmień powiększenie |
| kółko poza obrazem | poprzedni / następny obraz |
| prawy / środkowy przycisk na obrazie | przesuwaj powiększony obraz |
| środkowy przycisk na miniaturze | pokaż plik w menedżerze plików |
| środkowy przycisk na *Zapisz jako* | zapisz od razu, bez dialogu |
| `Ctrl`/`Shift` + klik miniatury | dodaj obraz do zaznaczenia wielu obrazów używanego dla kadrów `#N` albo usuń z niego; samo przeglądanie nie czyści zaznaczenia |

### Dane programu

| Ścieżka | Zawartość |
|---|---|
| `~/.config/kadr/state.json` | sesja: kadry, lista obrazów, schemat nazw i układ okna |
| `~/.cache/kadr/undo/` | kopie oryginałów używane przez *Cofnij* |
| `~/.cache/kadr/pasted/` | obrazy wklejone ze schowka (usuwane po 7 dniach) |

Flatpak zapisuje te same dane w `~/.var/app/org.kadr.kadr/config/kadr/` oraz `~/.var/app/org.kadr.kadr/cache/kadr/`.

## Rozwój

```sh
./install-local.sh            # instalacja w ~/.local/bin, z wpisem desktopowym i ikoną (bez roota)
./install-local.sh --restart  # instalacja, zamknięcie starej instancji i uruchomienie nowej
./install-local.sh --remove   # usuwa instalację lokalną; wersja AUR w /usr/bin pozostaje
./install-local.sh --package  # buduje pakiet i wyświetla polecenie instalacji
```

Repozytorium jest źródłem, a uruchamiana kopia znajduje się w `~/.local`. Po zmianie `kadr` użyj `--restart`, żeby skopiować plik i uruchomić nową wersję. Skrypt sprawdza składnię przed kopiowaniem. Nie instaluj lokalnie pakietu AUR do pracy nad programem: `~/.local/bin` i tak ma pierwszeństwo w `PATH`; `--remove` służy tylko do sprzątania.

### Budowanie pakietu AUR

```sh
git clone https://aur.archlinux.org/kadr.git
cd kadr
makepkg -si
```

### Wydanie nowej wersji

Pliki źródłowe aplikacji to `kadr`, `org.kadr.kadr.desktop`, `org.kadr.kadr.svg` i `org.kadr.kadr.metainfo.xml`. Przed każdym wydaniem zaktualizuj wpis wersji w metadanych AppStream i zwiększ nazwę cache service workera w `sw.js`, aby zaktualizować zainstalowane wersje demo w przeglądarce. Jedynym edytowanym przepisem pakietu jest główny [`PKGBUILD`](PKGBUILD); `.SRCINFO` powstaje podczas wydania i jest kopiowane do AUR. Archiwum źródłowe jest odtwarzalne z wypchniętego taga.

```sh
git add -A && git commit -m 'release: prepare 1.2.1'
git tag v1.2.1 && git push origin main --tags
./release.sh 1.2.1              # odtwarzalne archiwum -> GitHub Release + AUR
./release.sh --dry-run 1.2.1    # generuje i sprawdza artefakty bez publikowania
```

Skrypt wydania odmawia pracy na brudnym drzewie, wymaga taga wypchniętego na GitHub i sprawdza, czy asset na GitHubie zgadza się z `sha256` w `PKGBUILD`. Tworzy release GitHub, jeśli jeszcze nie istnieje, publikuje pakiet AUR i wysyła przypięty manifest Flatpaka jako asset wydania; ten manifest trzeba osobno zgłosić do Flathub. Nigdy nie wywołuje `sudo`.

## Uwagi

- *Zastąp oryginalne* nigdy nie nadpisuje pliku bez wcześniejszego utworzenia kopii. Jeśli zapis się nie uda, oryginał wraca na miejsce, a trwały komunikat pokazuje błąd i przycisk *Szczegóły*.
- Kadrowanie w miejscu nie nadpisuje formatu, którego system nie umie zapisać — zamiast tego zapisuje PNG obok oryginału.
- Program nie wysyła nic do sieci i dotyka tylko plików, które wczytasz lub wkleisz.

## Licencja

MIT — zobacz [LICENSE](LICENSE).

Zdjęcia w `demo.gif` pochodzą z [picsum.photos](https://picsum.photos).
