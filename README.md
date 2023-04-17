# spatial

`spatial` implements a spatial model inspired by Material Shell and
Paper WM, for Sway. More precisely, it organizes the windows in your
workspaces as if they are on a loop, showing only a fixed number at
a time.

It is implemented as a daemon, communicating with Sway using your
favorite tiling manager’s IPC protocol (if you are curious, have a
look at `man sway-ipc`!).

It is missing some features, but `spatial` can already by used
today. Here is an example of a configuration that works.

```bash
set $spatial "/usr/local/bin/spatial"
set $spatialmsg "/usr/local/bin/spatialmsg"

# Start the daemon when sway is started.
exec $spatialmsg

# Focus the previous window in the ribbon, that is on the left, if the
# focus is on the last window on the left of the visible area, windows
# will shift right to make room for the next candidate on the loop,
# and the window on the far right will disappear.
bindsym $mod+t exec $spatialmsg "focus prev"

# Same thing, for the right.
bindsym $mod+n exec $spatialmsg "focus next"

# Move the focused window on the left.
bindsym $mod+Shift+t exec $spatialmsg "move left"

# Move the focused window on the right.
bindsym $mod+Shift+n exec $spatialmsg "move right"

# Move the focused window on the upper workspace.
bindsym $mod+Shift+r exec $spatialmsg "move up"

# Move the focused window on the lower workspace.
bindsym $mod+Shift+s exec $spatialmsg "move down"

# Jump to the previous workspace (that is, N-1 for workspace N, but
# iff N > 0).
bindsym $mod+r exec $spatialmsg "workspace prev"

# Jump to the next workspace (that is, N+1 for workspace N).
bindsym $mod+s exec $spatialmsg "workspace next"

# Toggle between a mode where only one window is visible (maximized
# mode), or a fixed numbers (split mode). spatial will remember
# how may windows you want visible when not in full view mode.
bindsym $mod+space exec $spatialmsg "maximize toggle"

# Decrease the number of windows to display when in split mode.
bindsym $mod+g exec $spatialmsg "split decrement"

# Increase the number of windows to display when in split mode.
bindsym $mod+h exec $spatialmsg "split increment"
```

It is also possible to customize `spatial` itself, by creating a configuration
file at at `${HOME}/.config/spatial/config`.

The syntax is heavily inspired by Sway’s.

- `background "PATH"` will tell `spatial` to display the chosen background in
  empty workspaces (using `swaybg`).
- `default focus true|false` to decide whether or not `spatial` will prefer the
  maximized view for first visited workspace or not. If prefixed by
  `[workspace=n]`, then the rule only affects workspace `n`.
- `default visible windows n` will tell `spatial` to limit the number of
  visible windows in first visited workspaces to `n` (when the maximized mode
  is disable). If prefixed by `[workspace=n]`, then the rule only affects
  workspace `n`.

## Installing From Source

You will need `opam`.

```bash
# install dependencies
make build-deps
# install spatial
make install
```
