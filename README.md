# spatial-sway

`spatial-sway` implements a spatial model inspired by Material Shell
and Paper WM, for Sway. More precisely, it organizes the windows in
your workspaces as if they are on a loop, showing only a fixed number
at a time.

It is implemented as a daemon, communicating with Sway using your
favorite tiling manager’s IPC protocol (if you are curious, have a
look at `man sway-ipc`!).

It is missing some features, but `spatial-sway` can already by used
today. Here is an example of a configuration that works.

```
set $spatial "/usr/local/bin/spatial"
set $spatialmsg "/usr/local/bin/spatialmsg"

# Start the daemon when sway is started.
exec $spatialmsg

# Focus the next window on the left, if the focus is on the last window
# on the left of the visible area, windows will shift right to make room
# for the next candidate on the loop, and the window on the far right
# will disappear.
bindsym $mod+t exec $spatialmsg move_left

# Same thing, for the right.
bindsym $mod+n exec $spatialmsg move_right

# Move the focused window on the left, shift the loop if necessary.
bindsym $mod+Shift+t exec $spatialmsg move_window_left

# Move the focused window on the right, shift the loop if necessary.
bindsym $mod+Shift+n exec $spatialmsg move_window_right

# Toggle between a mode where only one window is visible, or a fixed
# numbers. spatial-sway will remember how may windows you want visible
# when not in full view mode.
bindsym $mod+space exec $spatialmsg toggle_full_view

# Decrease the number of windows to display when not in full view mode.
bindsym $mod+g exec $spatialmsg decr_maximum_visible_size

# Increase the number of windows to display when not in full view mode.
bindsym $mod+h exec $spatialmsg incr_maximum_visible_size
```
