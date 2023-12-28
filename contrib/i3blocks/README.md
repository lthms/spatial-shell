# `i3blocks` Configuration

In your i3 or sway configuration, you can add the following snippet.

```
bar {
  font pango: JetBrains Mono Nerd Font 12
  status_command i3blocks
  workspace_buttons no
  position top
}
```

In your Spatial Shell configuration, you should add this snippet.

```
status_bar_name i3blocks
```

This will work, assuming you copy `config` in `~/.config/i3blocks/config`.
