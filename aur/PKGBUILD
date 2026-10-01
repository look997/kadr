# Maintainer: look997 <look997@gmail.com>
#
# Single-file GTK4/libadwaita application: one crop for multiple images.
# No build step — install files directly from the v$pkgver tag.
pkgname=kadr
pkgver=1.2.0
pkgrel=1
pkgdesc='Batch crop multiple images with the same crop area (GTK4/libadwaita)'
arch=('x86_64')
url='https://github.com/look997/kadr'
license=('MIT')
depends=(
  gdk-pixbuf2
  gtk4
  libadwaita
  python-cairo
  python-gobject
)
# Gdk-pixbuf modules determine which image formats can be opened and saved.
# Without them, PNG/JPEG (and cached formats) are supported.
optdepends=(
  'libheif: HEIF/AVIF'
  'librsvg: SVG'
  'libtiff: TIFF'
  'libwebp: WebP'
  'nemo: show saved files selected in the file manager (org.freedesktop.FileManager1 ShowItems)'
)
# Use the v$pkgver release asset rather than the full tag snapshot, which includes
# screenshots and demo.gif (1.2 MB) to install a 56 kB application.
source=("$pkgname-$pkgver.tar.gz::$url/releases/download/v$pkgver/kadr-$pkgver.tar.gz")
sha256sums=('f774e5f08941266955e360a8f78404a46f7983ecc480cc224c5d021dd7389e68')

package() {
  cd "$pkgname-$pkgver"
  install -Dm755 kadr "$pkgdir/usr/bin/kadr"
  install -Dm644 local.Kadr.desktop "$pkgdir/usr/share/applications/local.Kadr.desktop"
  install -Dm644 local.Kadr.svg \
    "$pkgdir/usr/share/icons/hicolor/scalable/apps/local.Kadr.svg"
  install -Dm644 locale/en/LC_MESSAGES/kadr.mo \
    "$pkgdir/usr/share/locale/en/LC_MESSAGES/kadr.mo"
}