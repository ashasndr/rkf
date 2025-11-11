# rkf

rkf (RanK Format) is a Bash CLI tool to make it easier to make Monstercat/NCS rankings. I wanted to start ranking all Monstercat tracks, but I quickly noticed my old tool to make these could use some huge improvements, so i made this sort of v2.

## Installation
Dependencies: wl-copy OR xclipboard depending on if you're on Wayland or X11.
### Linux
```bash
git clone https://github.com/ashasndr/rkf.git
cd rkf
ln rkf.sh ~/.local/bin/rkf
```
### Windows
Pretty much the same as Linux but via [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

## Usage: 
```
rkf [options]
```
### Examples:
```bash
rkf -met --et 1410 --sb "with a few extra songs that i forgot last month"
```
will produce a "Ranking Monstercat October 2014" with a subtitle "with a few extra songs that i forgot last month", parsing songs from local files, with emotes

```
rkf -nes --et 1509
```
will produce a "Ranking NCS September 2015" with no subtitle and no markers, and gets its data from the clipboard

### Options:
```
  -n            Use the NCS scheme
  -m            Use the Monstercat scheme
  -e            Use VNF emojis for genres
  -r            Use the last saved file and continue editing it
  -s            Disable separators (-=-= :emoji: =-=-)
  -t            Get data from the TSV files saved
  -2            2 lines (Artists, Songs)
  -3            3 lines (Genre, Artists, Songs)
                if neither 2 or 3 are selected, it'll default to full document lines.
  -d            display (cat) after execution
  -l            display (less) after exec
  -c            DO NOT copy result after finished
  -w            Sets you to Windows (WSL) mode (but likely already auto-detects if you are on windows, only use if you are experiencing issues)

  --title "yourtext"        Set a title (Ranking (scheme) (yourtext))
        aka --ti
  --subtitle "yourtext"     Set the subtitle
        aka --sb
  --fulltitle "yourtext"    Set a title (yourtext)
        aka --ft
        aka --full
  --expresstitle YYMM       Set a title (Ranking (scheme) (MM converted to month) 20(YY))
        aka --et
        aka --yymm
  --updatedb                Update db of scheme -m/-n (must have the whole MCatalog/NCS info sheet copied to clipboard)
        aka --dbupd
        aka --db
  -h, --help                Display help
  --last                    Shows last output
  --err                     Shows last error
  --cperr                   Copies last error
  --cplast                  Copies last output
  --mcatalog                Copies MCatalog URL
  --monstercatplaylist      Copies Monstercat playlist URL
  --ncsinfo                 Copies NCS Info URL
  --ncsplaylist             Copies NCS playlist URL
  --changelog               Display changelogs
```

## Features to come (no promises)
- Config file 

