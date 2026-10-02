# Kadr

English | [Polski](README.pl.md)

Kadr is a GTK4/libadwaita application for cropping multiple images. Set one crop for every image, or create a separate crop for selected files.

The interface is available in English and Polish and follows your system locale.

![Kadr main window](screenshot.png)

![Browsing through the loaded images](demo.gif)

![Kadr save dialog](screenshot-dialog.png)

## Features

- **One crop for the whole list.** Set the crop once and apply it to every loaded image.
- **Individual crop (`#N`).** Selected images share a separate crop; the rest keep the general crop.
- **Browse without losing selection.** Ctrl/Shift-click selects thumbnails. Arrow keys, scrolling over the thumbnail panel, and ordinary thumbnail clicks continue to work without clearing the selection. Only Ctrl/Shift changes it; `Esc` or *Deselect* clears it.
- **Scale to fit.** Images with the same aspect ratio as the reference image receive a proportionally scaled crop (shown by a `%` badge on the thumbnail), useful for the same photos in different resolutions.
- **Save copies or replace originals.** *Save As* writes cropped copies beside the originals or to a chosen folder. *Replace originals* overwrites files only after making backups; *Undo* can restore them even after restarting the app.
- **Filename patterns.** The default is `[name]_%Y%m%d-%H%M%S`; `[name]`, `[nr]`, and `strftime` date codes are also available. The save dialog previews filenames, and the complete crop-and-save command can be copied to the clipboard.
- **Formats supported by the system.** Kadr reads formats supported by GdkPixbuf, such as JPEG, PNG, WebP, TIFF, AVIF, and HEIF. Formats without write support are saved as PNG beside the original.
- **Paste and drop.** Use Ctrl+V to paste a bitmap or files from the clipboard, drop images onto the window, or click the empty area to choose files.
- **Flexible thumbnail panel.** Place it at the bottom or on the right, or hide it. Drag its handle to change its height (number of thumbnail rows) or width.
- **Session restoration.** Crops, image list, filename pattern, panel position, and window size are saved and restored on restart.
- **Precise editing.** Set aspect ratios, zoom and pan the image, use a loupe, and undo crop changes.

## Browser demo

[Open the experimental HTML demo](https://look997.github.io/kadr/kadr.html). It is a separate work-in-progress version, may contain bugs, and is not a replacement for the desktop application.
The demo follows your browser language; override it with `?lang=en` or `?lang=pl`. It can be installed as a PWA and launched offline after its first load. Crop and session metadata are kept in the browser; after a reload, select the same image files again to restore them. The browser will not reopen local files without your permission.

## Installation

### Arch Linux (AUR)

```sh
yay -S kadr
```

[AUR package](https://aur.archlinux.org/packages/kadr)

### From the repository

```sh
git clone https://github.com/look997/kadr.git
cd kadr
sudo install -Dm755 kadr /usr/bin/kadr
sudo install -Dm644 io.github.look997.kadr.desktop /usr/share/applications/io.github.look997.kadr.desktop
sudo install -Dm644 io.github.look997.kadr.svg /usr/share/icons/hicolor/scalable/apps/io.github.look997.kadr.svg
sudo install -Dm644 io.github.look997.kadr.metainfo.xml /usr/share/metainfo/io.github.look997.kadr.metainfo.xml
```

Without root access, copy `kadr` to `~/bin/` or `~/.local/bin/` and add that directory to your `PATH`.

### Dependencies

GTK4, libadwaita, PyGObject, Pycairo, and GdkPixbuf are required. On Arch Linux, the packages are `gtk4`, `libadwaita`, `python-gobject`, `python-cairo`, and `gdk-pixbuf2`.
Available image formats depend on the installed GdkPixbuf modules, such as `librsvg` and `libheif`.

After installing the dependencies, run `./kadr`. For routine local desktop testing, `./install-local.sh --restart` installs a copy at `~/.local/bin/kadr` and restarts the application without root access.

### Flatpak

The Flatpak application ID is `io.github.look997.kadr`. GTK4 and libadwaita come from the shared GNOME runtime rather than a private bundle. Flathub requires the submission manifest to be prepared by the maintainer; do not use an AI-generated manifest.

After creating a release, build and install it locally (requires Flatpak, `flatpak-builder`, and the GNOME 51 SDK/runtime):

```sh
flatpak install --user flathub org.gnome.Platform//51 org.gnome.Sdk//51
flatpak-builder --user --install --force-clean build-dir io.github.look997.kadr.yml
flatpak run io.github.look997.kadr
```

The sandbox uses GTK file chooser portals and does not request broad access to the host filesystem.

Prepare your own Flathub manifest, pinned to a deterministic source archive from a GitHub Release, then build and test it before following Flathub's current new-app submission process. After approval, the app's repository will be `flathub/io.github.look997.kadr`; future updates are submitted there.

## Usage

```sh
kadr                    # open an empty window
kadr photos/*.jpg       # open matching files
kadr ~/Pictures         # open a folder
```

1. **Open images** using the button, by dropping files onto the window, or with Ctrl+V.
2. **Drag a crop** on the image. You can also enter its X, Y, width, and height numerically.
3. **Browse:** the mouse wheel over the image zooms; over the thumbnail panel it changes the current image.
4. **Save:**
   - *Save As* creates cropped copies using the filename pattern. Middle-click the button to save immediately with the last-used pattern, without opening the dialog.
   - *Replace originals* overwrites the files after backing them up; use *Undo* to restore them.

### Keyboard and mouse shortcuts

| Key / gesture | Action |
|---|---|
| `Ctrl+V` | Paste images or files from the clipboard |
| `Ctrl+A` | Select all thumbnails |
| `Esc` | Clear the selection |
| `←` `→` | Previous / next image (hold to scroll) |
| `↑` `↓` `+` `−` | Zoom |
| Mouse wheel over image | Zoom |
| Mouse wheel outside image | Next / previous image |
| Right / middle mouse button on image | Pan the zoomed image |
| Middle-click a thumbnail | Show the file in the file manager |
| Middle-click *Save As* | Save immediately without the dialog |
| `Ctrl`/`Shift` + click a thumbnail | Add/remove images from the multi-selection used for `#N` crops; browsing does not clear it |

### Application data

| Path | Contents |
|---|---|
| `~/.config/kadr/state.json` | Session: crops, image list, filename pattern, and window layout |
| `~/.cache/kadr/undo/` | Original-file backups used by *Undo* |
| `~/.cache/kadr/pasted/` | Images pasted from the clipboard (removed after 7 days) |

Flatpak stores the same data under `~/.var/app/io.github.look997.kadr/config/kadr/` and `~/.var/app/io.github.look997.kadr/cache/kadr/`.

## Development

```sh
./install-local.sh            # install to ~/.local/bin, with desktop entry and icon (no root)
./install-local.sh --restart  # install, close the old instance, and start the new one
./install-local.sh --remove   # remove the local install; leave the AUR version in /usr/bin
./install-local.sh --package  # build a package and print the install command
```

The repository is the source; the live copy is in `~/.local`. After changing `kadr`, run `--restart` to copy it and launch the new version. The script checks syntax before copying. Do not install the AUR package locally for development: `~/.local/bin` already takes precedence in `PATH`; `--remove` is only for cleanup.

### Building the AUR package

```sh
git clone https://aur.archlinux.org/kadr.git
cd kadr
makepkg -si
```

### Releasing a new version

The application sources are `kadr`, `io.github.look997.kadr.desktop`, `io.github.look997.kadr.svg`, and `io.github.look997.kadr.metainfo.xml`. Before each release, update the AppStream release entry in the metainfo file and increment the service-worker cache name in `sw.js` so installed browser demos receive the update. The root [`PKGBUILD`](PKGBUILD) is the only package recipe to edit; `.SRCINFO` is generated during release and copied to AUR. The source archive is reproducible from a pushed tag.

```sh
git add -A && git commit -m 'release: prepare 1.2.2'
git tag v1.2.2 && git push origin main --tags
./release.sh 1.2.2              # reproducible source archive -> GitHub release + AUR
./release.sh --dry-run 1.2.2    # generate and validate artifacts without publishing
```

The release script refuses to run on a dirty working tree, requires the tag to be pushed to GitHub, and checks that the GitHub asset matches the `sha256` in `PKGBUILD`. It creates the GitHub release if needed and publishes the AUR package. It never invokes `sudo`.

## Notes

- *Replace originals* never overwrites a file without first making a backup. If saving fails, the original is restored and a persistent toast shows the error with a *Details* button.
- In-place cropping does not overwrite a format the system cannot write; it saves a PNG beside the original instead.
- The program sends no data over the network and only touches files you load or paste.

## License

MIT — see [LICENSE](LICENSE).

The photos in `demo.gif` are from [picsum.photos](https://picsum.photos).
