#!/usr/bin/env bash
# kadr — wydanie: buduje tarball źródłowy z taga i publikuje (GitHub asset + AUR).
#
# Jedyne źródło prawdy jest DRZEWO ROBOCZE repo: kadr, local.Kadr.desktop, local.Kadr.svg.
# Ten skrypt jest jedynym miejscem, które zamienia te pliki w to, co widzi użytkownik:
#
#   pliki w repo ──git archive──> dist/kadr-$v.tar.gz ──gh release upload──> asset v$v
#                                        │
#                                        └─sha256──> PKGBUILD ──.SRCINFO──> aur/ ──> AUR
#
#   PKGBUILD/.SRCINFO/aur/ są GENEROWANE i nie wolno ich ręcznie edytować — to one
#   dostają dane, nie je dają.
#
# Użycie:
#   ./release.sh <wersja>        np. ./release.sh 1.0.1
#   ./release.sh --dry-run <v>   pokazuje co by zrobił, niczego nie wypycha
#
# Wymagania: czyste drzewo, tag v<wersja> istniejący i wypchnięty na GitHub,
# `gh` zalogowany. Skrypt NIGDY nie woła sudo.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

PKG=kadr
# jedyne trzy pliki, które trafiają do paczki — lista jest tu, żeby nie rozjechała się z package()
FILES=(kadr local.Kadr.desktop local.Kadr.svg)

DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; shift; fi
VER="${1:-}"
[ -n "$VER" ] || { echo "użycie: ./release.sh [--dry-run] <wersja>" >&2; exit 2; }

TAG="v$VER"
TARBALL="$PKG-$VER.tar.gz"
AUR_URL="ssh://aur@aur.archlinux.org/${PKG}.git"
PKG_PAGE="https://aur.archlinux.org/packages/${PKG}"

say() { printf -- '-> %s\n' "$*"; }
die() { printf -- '!! %s\n' "$*" >&2; exit 1; }

# 0) porządek: brak niescommitowanych zmian i tag musi już być wypchnięty
git diff --quiet || die "drzewo ma niescommitowane zmiany — commit najpierw"
git diff --cached --quiet || die "są zaindeksowane, niezacommitowane zmiany — commit najpierw"
[ -z "$(git ls-files --others --exclude-standard)" ] || die "są nieśledzone pliki — dopisz je do .gitignore albo commnij"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || die "brak taga $TAG"
git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1 \
  || die "tag $TAG nie jest na GitHubie — zrób: git tag $TAG && git push origin $TAG"

# 1) tarball źródłowy prosto z taga (nie z drzewa roboczego — tag jest tym, co wydajemy)
mkdir -p dist
say "tarball z $TAG: ${FILES[*]}"
git archive --format=tar.gz --prefix="$PKG-$VER/" -o "dist/$TARBALL" "$TAG" -- "${FILES[@]}"
SHA=$(sha256sum "dist/$TARBALL" | cut -d' ' -f1)
say "sha256 $SHA  ($(du -h "dist/$TARBALL" | cut -f1), $(tar -tzf "dist/$TARBALL" | grep -vc '/$') plików)"

# 2) PKGBUILD: wersja + sha256 wpinane, reszta nietknięta
say "PKGBUILD: pkgver=$VER, sha256sums"
sed -i -E "s|^pkgver=.*|pkgver=$VER|" PKGBUILD
sed -i -E "s|^sha256sums=\(.*\)|sha256sums=('$SHA')|" PKGBUILD
grep -qF "releases/download/v\$pkgver/$TARBALL" PKGBUILD \
  || die "PKGBUILD nie wskazuje source= na asset release v\$pkgver/$TARBALL — popraw tę linię ręcznie"

# 3) .SRCINFO generowany, aur/ lustrzane (aur/LICENSE = repo LICENSE; PKGBUILD deklaruje MIT)
say ".SRCINFO z PKGBUILD"
makepkg --printsrcinfo > .SRCINFO
cp PKGBUILD .SRCINFO LICENSE aur/
say "aur/ zsynchronizowane"

# 4) sprawdzenie, że package() zgadza się z listą FILES
for f in "${FILES[@]}"; do
  grep -q "install -Dm[0-9]* $f " PKGBUILD || die "package() nie instaluje $f, a jest na liście FILES"
done

if [ "$DRY" = 1 ]; then
  say "DRY RUN — koniec. Zmiany w PKGBUILD/.SRCINFO/aur/ zapisane lokalnie, nic nie wypchnięte."
  exit 0
fi

# 5) asset na GitHubie (idempotentnie: istniejący nie jest ruszany, bo sha go pilnuje)
if gh release view "$TAG" --json assets --jq '.assets[].name' 2>/dev/null | grep -qx "$TARBALL"; then
  say "asset $TARBALL już jest na $TAG (sha256 w PKGBUILD musi się zgadzać)"
  if [ "$(gh release download "$TAG" -p "$TARBALL" -D dist -O --clobber >/dev/null 2>&1 && sha256sum "dist/$TARBALL" | cut -d' ' -f1)" != "$SHA" ]; then
    die "asset $TARBALL na GitHubie ma INNY sha256 niż tarball z taga — ktoś podmienił asset albo taga nie wypchnięto. Usuń asseta i puść ponownie."
  fi
else
  say "wgrywam asset $TARBALL na release $TAG"
  gh release upload "$TAG" "dist/$TARBALL"
fi

# 6) AUR
say "push do AUR"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
git -c init.defaultBranch=master clone "$AUR_URL" "$WORK/$PKG" >/dev/null
cp PKGBUILD .SRCINFO LICENSE "$WORK/$PKG/"
( cd "$WORK/$PKG"
  git add PKGBUILD .SRCINFO LICENSE
  git diff --cached --quiet && { echo "   bez zmian w AUR"; exit 0; }
  git commit -q -m "${PKG}: ${VER}"
  git push -q origin HEAD:master )

say "gotowe: https://github.com/look997/$PKG/releases/tag/$TAG  ·  $PKG_PAGE"
