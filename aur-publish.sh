#!/usr/bin/env bash
# Publikacja pakietu w AUR — dokończenie jednym poleceniem, gdy konto i klucz są już ustawione.
#
# Wymaga:
#   1) konta na https://aur.archlinux.org,
#   2) klucza SSH dodanego w Account Settings -> SSH Public Keys.
# Pakiety nie trzeba zakładać przez WWW — repozytorium ${PKG}.git powstaje
# przy pierwszym pushu (klon daje "puste repozytorium").
#
# Użycie:  ./aur-publish.sh
set -euo pipefail

PKG=kadr
REPO="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "-> klonuję  ${PKG}.git"
git -c init.defaultBranch=master clone "ssh://aur@aur.archlinux.org/${PKG}.git" "$WORK/$PKG"
cd "$REPO"
makepkg --printsrcinfo > "$WORK/$PKG/.SRCINFO"
cp "$REPO/PKGBUILD" "$REPO/LICENSE" "$WORK/$PKG/"

cd "$WORK/$PKG"
git add PKGBUILD .SRCINFO LICENSE
if git diff --cached --quiet; then
  echo "-> bez zmian w stosunku do AUR, nie ma czego wysyłać"
  exit 0
fi
git commit -m "${PKG}: aktualizacja ($(date +%F))"
echo "-> wypycham"
git push origin HEAD:master
echo "-> gotowe: https://aur.archlinux.org/packages/${PKG}"