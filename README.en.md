# Kadr

[Polski](README.md) | [English](README.en.md)

Kadr is a GTK4/libadwaita application for cropping multiple images. Apply one crop area to every image, or set individual crops for selected files.

## Features

- Batch cropping with a shared crop area, or individual crops.
- Crop aspect ratios, zooming, panning, and crop undo history.
- Save cropped copies using a filename pattern, or replace originals with undo support.
- Image formats supported by the installed GdkPixbuf modules.

## Browser demo

[Open the experimental HTML demo](https://look997.github.io/kadr/kadr.html). This is a separate work-in-progress version; it may contain bugs and is not a replacement for the desktop application.

## Installation

On Arch Linux, install the package from the AUR:

```sh
yay -S kadr
```

The application requires GTK4, libadwaita, PyGObject, and Pycairo. After installing these dependencies, run `./kadr`, or use `./install-local.sh` for a local installation.

## Screenshots

![Kadr main window](screenshot.png)

![Save dialog](screenshot-dialog.png)

![Cropping animation](demo.gif)
