# KDE Connect nie ma nic wspólnego z kadr — to był błąd w AUR, nie w kodzie kadr.

# KDE Connect to narzędzie do komunikacji między telefonem a komputerem (powiadomienia, udostępnianie schowka itd.).
# Kadr to narzędzie do kadrowania obrazów — zupełnie inne.

# Problem był w **AUR**: 
#   - `aur-publish.sh` klonuje repozytorium AUR (które jest puste przy pierwszym pushu)
#   - `aur-publish.sh` kopiuje do niego `PKGBUILD`, `.SRCINFO`, `LICENSE` z katalogu `aur/`
#   - ale `kadr-1.0.0.tar.gz` (36 KB) nie istniał w repozytorium AUR — AUR oczekiwał `kadr-1.0.0.tar.gz` z taga `v1.0.0` (pełny snapshot repo, 1,2 MB)
#   - to spowodowało błąd `invalid value Sync` w hooku `kdeconnect-newver.hook` (linia 5), bo `git archive` z taga v1.0.0 nie zawierał `source=` w PKGBUILD

# Rozwiązanie:
#   1. `release.sh` buduje **dedykowany tarball** z taga (36 KB) zawierający tylko 3 pliki (kadr, desktop, svg)
#   2. `PKGBUILD` wskazuje na ten asset: `source=("$pkgname-$pkgver.tar.gz::$url/releases/download/v$pkgver/kadr-$pkgver.tar.gz")`
#   3. `makepkg` weryfikuje sha256 — teraz działa, bo asset jest poprawny
#   4. `aur-publish.sh` klonuje AUR, kopiuje PKGBUILD/.SRCINFO/LICENSE i wypycha — teraz działa

# Dlaczego to ważne dla Ciebie?
#   - AUR nie akceptuje "hacków" — musi być poprawny tarball z release asset
#   - Twoje lokalne `install-local.sh` działa idealnie (kopiuje z repo, nie z symlinka)
#   - AUR publish.sh już działa (klonuje, kopiuje, wypycha) — wystarczy uruchomić `./aur-publish.sh` po wgraniu assetu

# Co musisz zrobić teraz:
#   1. `gh release upload v1.0.0 dist/kadr-1.0.0.tar.gz` (asset 33717 B, 200 OK)
#   2. `./aur-publish.sh` (AUR już ma repo, tylko trzeba go zaktualizować)
#   3. `git commit -am 'release 1.0.0-1: asset release'` i `git push` — to Twoje polecenie, nie moje

# Nie musisz zmieniać niczego w kadrze — to, co widzisz w `~/.local/bin/kadr` i `~/.local/share/applications/local.Kadr.desktop` to jest dokładnie to, co jest w repo.