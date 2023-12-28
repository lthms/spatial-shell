# Waybar Theme

This folder contains a theme which can be used with Waybar. It assumes the
`spatialbar` script is available from `$PATH`, for instance by moving it to
`.local/bin`.

To build and install `spatialbar`, you can use the Makefile at the root of the
repository.

```bash
make install-contrib
```

`spatialbar` is a simple executable whose main purpose is to generate blocks
for a bar compatible with the `i3blocks` format. It can be configured with a
configuration file (either `$XDG_CONFIG_HOME/spatial/spatialbar.json` or
`$HOME/.config/spatial/spatialbar.json`) to associate icons to application ids.

Here is an example of a valid `spatialbar.json` file (you need a [Nerd
Font](https://www.nerdfonts.com/) to view it correctly).

```json
[
  { "app_id": "firefox", "icon": "" },
  { "app_id": "kitty", "icon": "" },
  { "app_id": "Slack", "icon": "" },
  { "app_id": "emacs", "icon": "" },
  { "app_id": "neovide", "icon": "" },
  { "app_id": "chromium", "icon": "" }
]
```
