### Repository URL

https://github.com/jwkicklighter/omarchy-lofi-player

### Category

Widgets

### Tags

bar, media

### Suggest a missing tag

_No response_

### Maintainer notes

Lofi player is a bar widget for [lofi-player](https://github.com/jwkicklighter/lofi-player),
a small Bash script (by the same author) that streams YouTube live audio through
mpv and yt-dlp. The widget is QML only: it runs `lofi` with argv arguments
(never through a shell) and renders all text as plain text.

When `lofi` isn't on the PATH or in `~/.local/bin`, the panel shows a setup view
instead of the player. From there the user can copy the lofi-player install
command, or click **Install for me**, which opens a floating terminal running
`curl -fsSL https://github.com/jwkicklighter/lofi-player/releases/latest/download/install | bash`.
Nothing runs until the user clicks; the command is shown in the panel first. That
installer installs mpv, yt-dlp, socat, jq, and curl with the system package
manager (using sudo). The README documents these dependencies, installation,
updating, and removal. The plugin writes no user configuration; its settings are
the standard bar widget settings in `shell.json`.

The repository and plugin are MIT-licensed. The root `preview.png` is a
screenshot of the plugin's panel on an Omarchy desktop.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
