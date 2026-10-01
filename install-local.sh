#!/usr/bin/env bash
# Lokalna instalacja kadr — do developmentu, bez AUR i bez roota.
#
#   ./install-local.sh                 dowiązanie: ~/.local/bin/kadr -> <repo>/kadr
#                                      (dopisujesz do pliku i uruchamiasz, jest żywo)
#   ./install-local.sh --copy          zwykła instalacja: kopia pliku + desktop + ikona w ~/.local
#   ./install-local.sh --package       buduje prawdziwą paczkę makepkg i wypisuje jej zawartość
#   ./install-local.sh --install-package  ...i instaluje ją przez sudo pacman -U (prosi o hasło)
#   ./install-local.sh --restart       zamyka działającą instancję i odpala nową
#
# Wszystkie tryby robią najpierw `python3 -m py_compile`, więc błąd składni wychodzi
# przed instalacją, a nie przy starcie programu.
#
# Push do AUR to osobna sprawa: ./aur-publish.sh (patrz skill aur-publish).
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin/kadr"
APPDIR="$HOME/.local/share/applications"
ICONDIR="$HOME/.local/share/icons/hicolor/scalable/apps"
DESKTOP=local.Kadr.desktop
ICON=local.Kadr.svg

MODE=link
DO_RESTART=0
DO_INSTALL=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \?//'; }

for arg in "$@"; do
  case "$arg" in
    --link)            MODE=link ;;
    --copy)            MODE=copy ;;
    --package)         MODE=package ;;
    --install-package) MODE=package; DO_INSTALL=1 ;;
    --restart)         DO_RESTART=1 ;;
    -h|--help)         usage; exit 0 ;;
    *)                 echo "nieznana opcja: $arg  (--help)" >&2; exit 2 ;;
  esac
done

# 1. Składnia — zawsze najpierw, na pliku prosto z repo.
echo "-> sprawdzam składnię"
python3 -m py_compile "$REPO/kadr"
echo "   OK"

install_shared() {
  install -Dm644 "$REPO/$DESKTOP" "$APPDIR/$DESKTOP"
  install -Dm644 "$REPO/$ICON" "$ICONDIR/$ICON"
  command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$APPDIR" >/dev/null 2>&1 || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 &&
    gtk-update-icon-cache -q -t -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
}

case "$MODE" in
  link)
    chmod +x "$REPO/kadr"
    mkdir -p "$(dirname "$BIN")"
    ln -sfn "$REPO/kadr" "$BIN"
    install_shared
    echo "-> $BIN -> $REPO/kadr"
    echo "   desktop: $APPDIR/$DESKTOP"
    echo "   ikona:   $ICONDIR/$ICON"
    ;;

  copy)
    install -Dm755 "$REPO/kadr" "$BIN"
    install_shared
    echo "-> zainstalowano kopię: $BIN"
    ;;

  package)
    cd "$REPO"
    rm -f ./*.pkg.tar.zst
    makepkg -f --noconfirm          # "libfakeroot internal error: payload not recognized!" jest nieszkodliwy
    PKG=$(ls -1t ./*.pkg.tar.zst | head -1)
    echo "-> paczka: $PKG"
    echo "-> zawartość:"
    bsdtar -tf "$PKG" | sed 's/^/   /'
    if [ "$DO_INSTALL" = 1 ]; then
      sudo pacman -U --noconfirm "$PKG"
    else
      echo "-> (bez instalacji; dodaj --install-package, jeśli chcesz sudo pacman -U)"
    fi
    ;;
esac

# 2. Restart — pozwala odpalić nową wersję bez klikania w ikony.
if [ "$DO_RESTART" = 1 ]; then
  pkill -f '[b]in/kadr' 2>/dev/null || true
  sleep 0.4
  nohup "$BIN" "${KADR_ARGS:-}" >/dev/null 2>&1 &
  disown 2>/dev/null || true
  sleep 1
  pgrep -af '[b]in/kadr' | head -1 | sed 's/^/-> uruchomiono: /'
fi

exit 0