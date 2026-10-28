<p align="center">
  <img src="docs/assets/logo.svg" alt="Sudoku" width="160" />
</p>

<p align="center">
  A Sudoku game written in Odin with raylib, for the desktop and the browser.
</p>

<p align="center">
  <a href="https://github.com/florentsorel/sudoku/actions/workflows/ci.yml">
    <img src="https://github.com/florentsorel/sudoku/actions/workflows/ci.yml/badge.svg" alt="CI" />
  </a>
  <a href="https://github.com/florentsorel/sudoku/releases">
    <img src="https://img.shields.io/github/v/release/florentsorel/sudoku?color=blue&label=release" alt="Latest release" />
  </a>
  <img src="https://img.shields.io/badge/odin-dev--2026--10-3882d2" alt="Odin version" />
  <img src="https://img.shields.io/badge/raylib-6.0-black" alt="raylib 6.0" />
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License" />
</p>

---

## Overview

A complete Sudoku: random puzzles with a unique solution, three difficulties, pencil notes, undo,
hints and a timer. It runs natively on Linux, macOS and Windows, and in the browser through
WebAssembly.

The game logic lives in its own `puzzle` package, independent of raylib and covered by tests.
The project is also a way to learn Odin: it was built step by step, from an empty window to the
generator.

**[Play in the browser →](https://florentsorel.github.io/sudoku/)**

---

## Features

- **Puzzle generator** — every grid is random and has exactly one solution. Easy, Medium and Hard
  give 40, 32 and about 26 starting digits.
- **Highlights** — the row, column and box of the selected cell, and every cell holding the same
  digit. Toggle them with <kbd>G</kbd> or from the menu.
- **Conflicts** — a digit that clashes with another one in its row, column or box turns red.
- **Pencil notes** — switch to note mode with <kbd>N</kbd>. Placing a digit removes it from the
  notes of the cells it sees.
- **Undo** — every edit can be undone, notes included.
- **Hints** — reveal the right digit of a cell. The win screen tells how many you used.
- **Timer** — paused when the window loses focus.
- **Autosave** — the current puzzle is saved after every move and offered under *Continue*.
- **Feedback** — a short sound on each move, and rows, columns and boxes light up when completed.
  Sounds are synthesized at startup: there is no audio file to ship.
- **Self-contained** — the font is embedded in the executable.

---

## Download

| Platform | How |
|---|---|
| Browser | [florentsorel.github.io/sudoku](https://florentsorel.github.io/sudoku/) |
| Linux, macOS, Windows | Download the archive for your system from the [latest release](https://github.com/florentsorel/sudoku/releases/latest) |

> **macOS** — the binary is not signed. If macOS refuses to open it, right-click it and pick
> *Open*, or run `xattr -d com.apple.quarantine sudoku`.

---

## Controls

| Key | Action |
|---|---|
| Click, <kbd>←</kbd> <kbd>↑</kbd> <kbd>→</kbd> <kbd>↓</kbd> | Select a cell |
| <kbd>1</kbd>–<kbd>9</kbd> | Write a digit, or toggle a note in note mode |
| <kbd>Backspace</kbd> / <kbd>Delete</kbd> | Clear the cell |
| <kbd>N</kbd> | Note mode on/off |
| <kbd>H</kbd> | Hint |
| <kbd>U</kbd> or <kbd>Cmd</kbd>/<kbd>Ctrl</kbd>+<kbd>Z</kbd> | Undo |
| <kbd>G</kbd> | Highlights on/off |
| <kbd>Cmd</kbd>/<kbd>Ctrl</kbd>+<kbd>R</kbd> | New puzzle, same difficulty |
| <kbd>Esc</kbd> | Back to the menu |
| <kbd>F11</kbd> | Full screen (desktop) |

Keys are read by their physical position, as on a US keyboard. On AZERTY, <kbd>Cmd</kbd>+<kbd>Z</kbd>
is the key labelled W: use <kbd>U</kbd> instead.

---

## Building from source

You need [Odin](https://odin-lang.org/docs/install/) `dev-2026-10`. raylib comes with Odin
(`vendor:raylib`), nothing else to install.

```sh
# Run in debug: F2 shows the win screen, F3 solves the grid, leaks are reported on exit
odin run . -debug

# Optimized build
odin build . -o:speed -out:build/sudoku
```

On Linux, raylib also needs the X11, OpenGL and ALSA development packages, for example on
Debian or Ubuntu:

```sh
sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev \
  libglu1-mesa-dev libxcursor-dev libxinerama-dev
```

### Web build

The web build also needs [Emscripten](https://emscripten.org/docs/getting_started/downloads.html)
(`emcc` in your `PATH`). The Odin release archives include raylib's web library; some package
managers (Homebrew) strip it.

```sh
./build_web.sh
python3 -m http.server -d build/web 8000
```

Then open [http://localhost:8000](http://localhost:8000). The page has to be served over HTTP,
opening `index.html` as a file does not work.

### Tests

```sh
odin test . -all-packages -vet
```

---

## Project structure

```
sudoku/
├── main.odin              # Desktop entry point
├── main_web.odin          # Web entry points, called from JavaScript
├── game.odin              # Game state, screens, init / frame / shutdown
├── screen_menu.odin       # One file per screen
├── screen_play.odin
├── screen_won.odin
├── input.odin             # Keyboard and mouse on the grid
├── render.odin            # Grid, digits, highlights, palette
├── history.odin           # Undo
├── sounds.odin            # Synthesized sounds
├── save.odin              # Save and settings, as JSON
├── store_desktop.odin     # ...written to files on the desktop
├── store_web.odin         # ...or to localStorage in the browser
├── puzzle/                # Sudoku rules, solver and generator, no raylib
├── web/index_template.html
└── build_web.sh
```

---

## Saves

The current puzzle and the settings are stored as JSON:

| Platform | Location |
|---|---|
| macOS | `~/Library/Application Support/sudoku-odin/` |
| Linux | `~/.local/share/sudoku-odin/` |
| Windows | `%LOCALAPPDATA%\sudoku-odin\` |
| Browser | `localStorage`, under `sudoku-odin/` |

---

## Releases

Push a tag such as `v1.0.0`: the *Release* workflow builds Linux, macOS, Windows and the web
version, and attaches them to a GitHub release. Every push to `main` deploys the web version to
GitHub Pages.

---

## Credits

- [raylib](https://www.raylib.com/) by Ramon Santamaria, through Odin's `vendor:raylib`.
- [Inter](https://rsms.me/inter/) font by Rasmus Andersson, under the SIL Open Font License.
- The web build is based on [odin-raylib-web](https://github.com/karl-zylinski/odin-raylib-web)
  by Karl Zylinski.

---

## License

MIT
