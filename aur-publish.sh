#!/usr/bin/env bash
# Publikacja pakietu w AUR — dokończenie jednym poleceniem, gdy konto i klucz są już ustawione.
#
# Wymaga:
#   1) konta na https://aur.archlinux.org,
#   2) klucza SSH dodanego w Account Settings -> SSH Public Keys,
#   3) utworzonego pakietu (pkgbase) o nazwie "kadr":
#      https://aur.archlinux.org/pkgbase/add/
#
# Użycie:  ./aur-publish.sh
set -euo pipefail

PKG=kadr
SRC="$(cd "$(dirname "$0")" && pwd)/aur"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "-> klonuję  ${PKG}.git"
git clone "aur.archlinux.org:${PKG}.git" "$WORK/$PKG"
cp "$SRC/PKGBUILD" "$SRC/.SRCINFO" "$WORK/$PKG/"

cd "$WORK/$PKG"
git add PKGBUILD .SRCINFO
if git diff --cached --quiet; then
  echo "-> bez zmian w stosunku do AUR, nie ma czego wysyłać"
  exit 0
fi
git commit -m "${PKG}: aktualizacja ($(date +%F))"
echo "-> wypycham"
git push origin HEAD:master
echo "-> gotowe: https://aur.archlinux.org/packages/${PKG}"