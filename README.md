# rkf

rkf (RanK Format) is a Bash CLI tool to make it easier to make Monstercat/NCS rankings. I wanted to start ranking all Monstercat tracks, but I quickly noticed my old tool to make these could use some huge improvements, so i made this sort of v2.

## Installation

Dependencies:

- wl-copy OR xclipboard depending on if you're on Wayland or X11. Run `echo $XDG_SESSION_TYPE` to know.
- Bash v4+, run `echo $BASH_VERSION` to know
- Nano, except if you edit the config.conf file to use another editor

### Linux

```bash
git clone https://github.com/ashasndr/rkf.git
cd rkf
ln rkf.sh ~/.local/bin/rkf
```

### Windows

Pretty much the same as Linux but via [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

## Usage:

Check the wiki of this repo.

## Features to come (no promises)

- Code cleanup
- More queries possible with tsv imports
- Extra config options
