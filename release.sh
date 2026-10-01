#!/usr/bin/env bash
# kadr — wydanie: buduje tarball źródłowy z taga i publikuje (GitHub asset + AUR).
#
# Jedyne źródło prawdy jest DRZEWO ROBOCZE repo: aplikacja, desktop, ikona i katalog tłumaczeń.
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
# jedyne pliki, które trafiają do paczki — lista jest tu, żeby nie rozjechała się z package()
FILES=(kadr local.Kadr.desktop local.Kadr.svg locale/en/LC_MESSAGES/kadr.mo)

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
sha() { sha256sum "$1" | cut -d' ' -f1; }

# 0) porządek: brak niescommitowanych zmian i tag musi już być wypchnięty
git diff --quiet || die "drzewo ma niescommitowane zmiany — commit najpierw"
git diff --cached --quiet || die "są zaindeksowane, niezacommitowane zmiany — commit najpierw"
[ -z "$(git ls-files --others --exclude-standard)" ] || die "są nieśledzone pliki — dopisz je do .gitignore albo commnij"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || die "brak taga $TAG"
git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1 \
  || die "tag $TAG nie jest na GitHubie — zrób: git tag $TAG && git push origin $TAG"

# 1) tarball źródłowy prosto z taga (nie z drzewa roboczego — tag jest tym, co wydajemy).
#    gzip -n bez znacznika czasu + tar z dat commitów = te same bajty za każdym razem,
#    więc sha256 da się porównać z tym, co jest na GitHubie.
mkdir -p dist
say "tarball z $TAG: ${FILES[*]}"
git archive --format=tar --prefix="$PKG-$VER/" "$TAG" -- "${FILES[@]}" | gzip -n -9 > "dist/$TARBALL"
SHA=$(sha "dist/$TARBALL")
say "sha256 $SHA  ($(du -h "dist/$TARBALL" | cut -f1), $(tar -tzf "dist/$TARBALL" | grep -vc '/$') plików)"

# 2) PKGBUILD: wersja + sha256, reszta nietknięta
grep -qF 'releases/download/v$pkgver/kadr-$pkgver.tar.gz' PKGBUILD \
  || die "PKGBUILD nie wskazuje source= na asset release v\$pkgver/kadr-\$pkgver.tar.gz — popraw tę linię ręcznie"

# 3) co jest już na GitHubie dla tego taga?
REMOTE_SHA=""
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if gh release view "$TAG" --json assets --jq '.assets[].name' 2>/dev/null | grep -qx "$TARBALL"; then
  gh release download "$TAG" -p "$TARBALL" -D "$TMP" >/dev/null 2>&1 || true
  [ -f "$TMP/$TARBALL" ] && REMOTE_SHA=$(sha "$TMP/$TARBALL")
fi
OLD_SHA=$(sed -nE "s/^sha256sums=\('([0-9a-f]+)'\)/\1/p" PKGBUILD)

if [ -n "$REMOTE_SHA" ] && [ "$REMOTE_SHA" != "$SHA" ]; then
  if [ "$REMOTE_SHA" = "$OLD_SHA" ]; then
    # asset na GitHubie zgadza się z tym, co PKGBUILD już zapowiadał; lokalny rebuild
    # różni się bajtami (np. tarball zrobiony --format=tar.gz, czyli z czasem w gzipie).
    # Wersjonę wgrywamy dalej; od teraz tarball jest deterministyczny.
    say "asset $TARBALL na GitHubie ma inny bajt-z-bajt, ale zgodny z PKGBUILD sha — zostawiam PKGBUILD"
    SHA="$REMOTE_SHA"
  else
    die "asset $TARBALL na GitHubie ma sha $REMOTE_SHA, a PKGBUILD obiecywał $OLD_SHA — ktoś podmienił asseta albo taga nie wypchnięto. Usuń asseta i puść ponownie."
  fi
fi

say "PKGBUILD: pkgver=$VER, sha256sums=$SHA"
sed -i -E "s|^pkgver=.*|pkgver=$VER|" PKGBUILD
sed -i -E "s|^sha256sums=\(.*\)|sha256sums=('$SHA')|" PKGBUILD

# 4) sprawdzenie, że package() zgadza się z listą FILES, potem .SRCINFO + aur/
for f in "${FILES[@]}"; do
  grep -q "install -Dm[0-9]* $f " PKGBUILD || die "package() nie instaluje $f, a jest na liście FILES"
done
say ".SRCINFO z PKGBUILD"
makepkg --printsrcinfo > .SRCINFO
cp PKGBUILD .SRCINFO LICENSE aur/
say "aur/ zsynchronizowane"

if [ "$DRY" = 1 ]; then
  say "DRY RUN — koniec. Zmiany w PKGBUILD/.SRCINFO/aur/ zapisane lokalnie, nic nie wypchnięte."
  exit 0
fi

# 5) asset na GitHubie
if [ -n "$REMOTE_SHA" ]; then
  say "asset $TARBALL już jest na $TAG i zgadza się z PKGBUILD"
else
  say "wgrywam asset $TARBALL na release $TAG"
  gh release upload "$TAG" "dist/$TARBALL"
fi

# 6) AUR
say "push do AUR"
WORK="$TMP/aur"
git -c init.defaultBranch=master clone "$AUR_URL" "$WORK" >/dev/null
cp PKGBUILD .SRCINFO LICENSE "$WORK/"
( cd "$WORK"
  git add PKGBUILD .SRCINFO LICENSE
  git diff --cached --quiet && { echo "   bez zmian w AUR"; exit 0; }
  git commit -q -m "${PKG}: ${VER}"
  git push -q origin HEAD:master )

say "gotowe: https://github.com/look997/$PKG/releases/tag/$TAG  ·  $PKG_PAGE"
