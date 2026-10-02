#!/usr/bin/env bash
# kadr — deterministic source release and AUR publishing.
#
# Jedyne źródło prawdy jest DRZEWO ROBOCZE repo: aplikacja, desktop, ikona i katalog tłumaczeń.
# Ten skrypt jest jedynym miejscem, które zamienia te pliki w to, co widzi użytkownik:
#
# files in repo ──git archive──> dist/kadr-$v.tar.gz ──gh release upload──> asset v$v
#                                         ├─sha256──> PKGBUILD ──.SRCINFO──> AUR
#                                         └─sha256──> Flatpak manifest ──> Flathub PR
#
# PKGBUILD is the sole source of truth; .SRCINFO and the Flatpak source pin are generated.
#
# Użycie:
#   ./release.sh <wersja>                np. ./release.sh 1.2.1
#   ./release.sh --dry-run <wersja>      pokazuje co by zrobił, niczego nie wypycha
#
# Wymagania: czyste drzewo, tag v<wersja> istniejący i wypchnięty na GitHub,
# `gh` zalogowany. Skrypt NIGDY nie woła sudo.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

say() { printf -- '-> %s\n' "$*"; }
die() { printf -- '!! %s\n' "$*" >&2; exit 1; }
sha() { sha256sum "$1" | cut -d' ' -f1; }

PKG=kadr
# jedyne pliki, które trafiają do paczki — lista jest tu, żeby nie rozjechała się z package()
FILES=(kadr org.kadr.kadr.desktop org.kadr.kadr.svg org.kadr.kadr.metainfo.xml locale/en/LC_MESSAGES/kadr.mo)

DRY=0
VER=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "nieznana opcja: $1" >&2
      exit 2
      ;;
    *)
      [ -z "$VER" ] || { echo "podaj tylko jedną wersję" >&2; exit 2; }
      VER="$1"
      ;;
  esac
  shift
done
[ -n "$VER" ] || { echo "użycie: ./release.sh [--dry-run] <wersja>" >&2; exit 2; }
[[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] \
  || die "niepoprawny format wersji: $VER"

TAG="v$VER"
TARBALL="$PKG-$VER.tar.gz"
AUR_URL="ssh://aur@aur.archlinux.org/${PKG}.git"
PKG_PAGE="https://aur.archlinux.org/packages/${PKG}"

# 0) Require clean, tagged sources and matching AppStream release metadata.
git diff --quiet || die "drzewo ma niescommitowane zmiany — commit najpierw"
git diff --cached --quiet || die "są zaindeksowane, niezacommitowane zmiany — commit najpierw"
[ -z "$(git ls-files --others --exclude-standard)" ] || die "są nieśledzone pliki — dopisz je do .gitignore albo commnij"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || die "brak taga $TAG"
git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1 \
  || die "tag $TAG nie jest na GitHubie — zrób: git tag $TAG && git push origin $TAG"
grep -qF "<release version=\"$VER\"" org.kadr.kadr.metainfo.xml \
  || die "brak wpisu AppStream dla wersji $VER — zaktualizuj org.kadr.kadr.metainfo.xml przed tagiem"
for f in "${FILES[@]}"; do
  git cat-file -e "$TAG:$f" 2>/dev/null || die "plik $f nie należy do taga $TAG"
done

# 1) Source tarball from the tag (never from the working tree).
#    gzip -n plus git archive's commit timestamps makes the archive reproducible.
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
AUR_STAGE="$TMP/aur-stage"
mkdir -p "$AUR_STAGE"
cp PKGBUILD LICENSE "$AUR_STAGE/"
sed -i -E "s|^pkgver=.*|pkgver=$VER|" "$AUR_STAGE/PKGBUILD"
sed -i -E "s|^sha256sums=\(.*\)|sha256sums=('$SHA')|" "$AUR_STAGE/PKGBUILD"

# 4) Verify package() covers FILES and generate metadata outside the worktree.
for f in "${FILES[@]}"; do
  grep -q "install -Dm[0-9]* $f " PKGBUILD || die "package() nie instaluje $f, a jest na liście FILES"
done
say ".SRCINFO z PKGBUILD"
makepkg --printsrcinfo --dir "$AUR_STAGE" > "$AUR_STAGE/.SRCINFO"

# Keep a release-pinned manifest as an explicit handoff artifact for Flathub.
FLATPAK_MANIFEST_TEMPLATE="$REPO/flatpak/org.kadr.kadr.yml.in"
FLATPAK_RELEASE_MANIFEST="$REPO/dist/org.kadr.kadr.yml"
sed -E \
  -e "s|^        url: .*|        url: https://github.com/look997/kadr/releases/download/$TAG/$TARBALL|" \
  -e "s|^        sha256: .*|        sha256: $SHA|" \
  "$FLATPAK_MANIFEST_TEMPLATE" > "$FLATPAK_RELEASE_MANIFEST"
grep -qF 'SOURCE_ARCHIVE_' "$FLATPAK_RELEASE_MANIFEST" \
  && die "nie udało się wypełnić źródła w manifeście Flatpaka"
say "manifest Flathub: $FLATPAK_RELEASE_MANIFEST"

if [ "$DRY" = 1 ]; then
  say "DRY RUN — wygenerowano archiwum i metadane, niczego nie wypchnięto ani nie zmieniono w źródłach."
  exit 0
fi

# 5) Upload the source archive; AUR and Flathub both build from this exact artifact.
OPTIONAL_FAILURES=()
if gh release view "$TAG" >/dev/null 2>&1; then
  say "release $TAG już istnieje"
else
  say "tworzę release $TAG"
  gh release create "$TAG" --title "$PKG $VER" --generate-notes
fi

if [ -n "$REMOTE_SHA" ]; then
  say "asset $TARBALL już jest na $TAG i zgadza się z PKGBUILD"
else
  say "wgrywam asset $TARBALL na release $TAG"
  gh release upload "$TAG" "dist/$TARBALL"
fi

# Publish the matching pinned manifest as a companion asset for the Flathub submission.
FLATPAK_RELEASE_NAME="$(basename "$FLATPAK_RELEASE_MANIFEST")"
if gh release view "$TAG" --json assets --jq '.assets[].name' 2>/dev/null | grep -qx "$FLATPAK_RELEASE_NAME"; then
  rm -f "$TMP/$FLATPAK_RELEASE_NAME"
  gh release download "$TAG" -p "$FLATPAK_RELEASE_NAME" -D "$TMP" >/dev/null 2>&1 \
    || die "manifest Flatpaka już istnieje, ale nie można go pobrać do porównania"
  cmp -s "$FLATPAK_RELEASE_MANIFEST" "$TMP/$FLATPAK_RELEASE_NAME" \
    || die "manifest Flatpaka już istnieje z inną treścią — nie nadpisuję assetu"
  say "asset $FLATPAK_RELEASE_NAME już jest na $TAG i jest zgodny"
else
  say "wgrywam manifest Flatpaka na release $TAG"
  gh release upload "$TAG" "$FLATPAK_RELEASE_MANIFEST"
fi

# 7) Publish AUR from the single canonical PKGBUILD in the repository root.
publish_aur() {
  local work="$TMP/aur"
  git -c init.defaultBranch=master clone "$AUR_URL" "$work" >/dev/null || return 1
  cp "$AUR_STAGE/PKGBUILD" "$AUR_STAGE/.SRCINFO" LICENSE "$work/" || return 1
  (
    cd "$work" || exit 1
    git add PKGBUILD .SRCINFO LICENSE || exit 1
    if git diff --cached --quiet; then
      echo "   bez zmian w AUR"
      exit 0
    fi
    git commit -q -m "${PKG}: ${VER}" || exit 1
    git push -q origin HEAD:master
  )
}

say "publikuję AUR"
if ! publish_aur; then
  say "publikacja AUR nie powiodła się"
  OPTIONAL_FAILURES+=("AUR")
fi

say "źródło: https://github.com/look997/$PKG/releases/tag/$TAG  ·  AUR: $PKG_PAGE"
if [ "${#OPTIONAL_FAILURES[@]}" -gt 0 ]; then
  printf '!! niepowodzenia (pozostałe kanały uruchomiono niezależnie): %s\n' \
    "$(IFS=', '; echo "${OPTIONAL_FAILURES[*]}")" >&2
  exit 1
fi
say "wydanie zakończone"
