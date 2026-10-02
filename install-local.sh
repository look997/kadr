#!/usr/bin/env bash
# kadr — instalacja lokalna (do pracy nad kodem). Wzorzec lookDev: źródło w ~/lookDev,
# żywa kopia w docelówce. Kopia, nie symlink.
#
#   ./install-local.sh              instaluje: ~/.local/bin/kadr + desktop + ikona w ~/.local
#                                  (cp, bez sudo, idempotentnie) — to jest tryb pracy
#   ./install-local.sh --restart    to samo + zamknięcie starej instancji i start nowej
#   ./install-local.sh --remove     usuwa instalację lokalną (żeby zostało tylko AUR /usr/bin)
#   ./install-local.sh --package    buduje paczkę makepkg i wypisuje zawartość + komendę
#                                  instalacji do wpisania w terminalu
#
# Skrypt NIGDY nie woła sudo — komendę z rootem dostajesz do wpisania w swoim terminalu.
# Push do AUR to osobna sprawa: ./aur-publish.sh (skill aur-publish).
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin/kadr"
APPDIR="$HOME/.local/share/applications"
ICONDIR="$HOME/.local/share/icons/hicolor/scalable/apps"
DESKTOP=org.kadr.kadr.desktop
ICON=org.kadr.kadr.svg

MODE=install
DO_RESTART=0

usage() { sed -n '2,15p' "$0" | sed 's/^# \?//'; }

for arg in "$@"; do
  case "$arg" in
    --install|--restart-install) MODE=install ;;
    --restart)                   MODE=install; DO_RESTART=1 ;;
    --remove)                    MODE=remove ;;
    --package)                   MODE=package ;;
    -h|--help)                   usage; exit 0 ;;
    *)                           echo "nieznana opcja: $arg  (--help)" >&2; exit 2 ;;
  esac
done

install_files() {
  install -Dm755 "$REPO/kadr" "$BIN"
  # Exec wskazuje na ~/.local/bin/kadr (nie "kadr"), żeby wpis działał niezależnie od PATH.
  sed 's|^Exec=kadr %F|Exec='"$BIN"' %F|' "$REPO/$DESKTOP" > "$APPDIR/$DESKTOP.new"
  install -Dm644 "$APPDIR/$DESKTOP.new" "$APPDIR/$DESKTOP"
  rm -f "$APPDIR/$DESKTOP.new"
  install -Dm644 "$REPO/org.kadr.kadr.svg" "$ICONDIR/$ICON"
  rm -f "$APPDIR/local.Kadr.desktop" "$ICONDIR/local.Kadr.svg"
  command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$APPDIR" >/dev/null 2>&1 || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 &&
    gtk-update-icon-cache -q -t -f "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
}

case "$MODE" in
  install)
    echo "-> sprawdzam składnię"
    python3 -m py_compile "$REPO/kadr"
    echo "   OK"
    install_files
    echo "-> $BIN (kopia z $REPO/kadr)"
    echo "   desktop: $APPDIR/$DESKTOP"
    echo "   ikona:   $ICONDIR/$ICON"
    echo "   uwaga: ~/.local/bin jest przed /usr/bin w PATH — jeśli kadr jest też z AUR,"
    echo "          to uruchamia się ta kopia. Do odwrócenia: --remove"
    ;;

  remove)
    rm -f "$BIN" "$APPDIR/$DESKTOP" "$ICONDIR/$ICON" \
      "$APPDIR/local.Kadr.desktop" "$ICONDIR/local.Kadr.svg"
    command -v update-desktop-database >/dev/null 2>&1 &&
      update-desktop-database "$APPDIR" >/dev/null 2>&1 || true
    echo "-> usunięte: $BIN, $APPDIR/$DESKTOP, $ICONDIR/$ICON"
    echo "   stan pakietu: $(pacman -Q kadr 2>/dev/null || echo 'kadr nie zainstalowany przez pacmana')"
    ;;

  package)
    cd "$REPO"
    rm -f ./*.pkg.tar.zst
    makepkg -f --noconfirm     # "libfakeroot internal error: payload not recognized!" jest nieszkodliwy
    PKG=$(ls -1t ./*.pkg.tar.zst | head -1)
    echo "-> paczka: $PKG"
    echo "-> zawartość:"
    bsdtar -tf "$PKG" | sed 's/^/   /'
    echo "-> instalacja (wpisz w swoim terminalu):"
    echo "     cd $REPO && sudo pacman -U --noconfirm $PKG"
    ;;
esac

if [ "$DO_RESTART" = 1 ]; then
  pkill -f '[b]in/kadr' 2>/dev/null || true
  sleep 0.4
  nohup "$BIN" >/dev/null 2>&1 &
  disown 2>/dev/null || true
  sleep 1
  pgrep -af '[b]in/kadr' | head -1 | sed 's/^/-> uruchomiono: /'
fi

exit 0