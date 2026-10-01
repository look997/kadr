# Kadr

[Polski](README.md) | [English](README.en.md)

Kadr to aplikacja GTK4/libadwaita do kadrowania wielu obrazów. Zaznaczony obszar kadru można zastosować do wszystkich obrazów albo ustawić osobny kadr dla wybranych plików.

Interfejs jest dostępny po polsku i angielsku; język wybierany jest na podstawie ustawień systemu.

## Funkcje

- Kadrowanie wielu obrazów tym samym obszarem i kadrowanie indywidualne.
- Proporcje kadru, powiększenie, przesuwanie obrazu oraz historia cofania.
- Zapis przyciętych kopii według schematu nazwy albo zastępowanie oryginałów z możliwością cofnięcia.
- Formaty obsługiwane przez zainstalowane moduły GdkPixbuf.

## Demo w przeglądarce

[Otwórz eksperymentalne demo HTML](https://look997.github.io/kadr/kadr.html). To osobna, robocza wersja — może zawierać błędy i nie zastępuje aplikacji desktopowej.
Język interfejsu demo jest dobierany według języka przeglądarki; można go wymusić przez `?lang=en` lub `?lang=pl`.

## Instalacja

W Arch Linux aplikację można zainstalować z AUR:

```sh
yay -S kadr
```

Do uruchomienia potrzebne są GTK4, libadwaita, PyGObject i Pycairo. Po ich zainstalowaniu można uruchomić `./kadr` albo użyć `./install-local.sh` do lokalnej instalacji.

## Zrzuty ekranu

![Główne okno Kadr](screenshot.png)

![Dialog zapisu](screenshot-dialog.png)

![Animacja kadrowania](demo.gif)
