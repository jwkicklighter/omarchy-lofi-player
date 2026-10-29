# Lofi player for Omarchy

An Omarchy shell bar widget for [lofi-player](https://github.com/jwkicklighter/lofi-player),
the `lofi` script that streams YouTube live audio through mpv.

- **Left-click** opens the player: play/pause, stop, favorite, volume, and the
  live streams from your channels (favorites first). Click a stream to play it.
- **Right-click** plays or pauses (resuming the last stream when stopped).
- **Middle-click** stops.
- **Scroll** changes volume by 5%.

If `lofi` isn't on your PATH (or in `~/.local/bin`), the panel offers setup
instead: check again, copy the install command, or click **Install for me** to
run the installer in a floating terminal. The widget switches to the player as
soon as the script appears.

## Install

```sh
git clone <this repo> ~/.config/omarchy/plugins/jwkicklighter.lofi-player
omarchy plugin enable jwkicklighter.lofi-player --section right
```

Settings (in `~/.config/omarchy/shell.json` on the widget entry, or with
`omarchy bar set jwkicklighter.lofi-player <key> <value>`):

| Key | Default | |
|---|---|---|
| `showVolume` | `false` | Show the volume next to the icon while playing |
| `refreshIntervalSec` | `3` | How often to poll `lofi status` while the panel is closed |

## Development

`LofiModel.js` holds the parsing of `lofi status`, `lofi list`, and
`lofi favorite list`. Test it with:

```sh
node tests/model.test.js
```

Stream titles go to `lofi` as argv elements, never through a shell, and all
text is rendered with `Text.PlainText`.
