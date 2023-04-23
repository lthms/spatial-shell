spatial(1)

# NAME

spatial - Implementing a spatial model inspired by Material Shell and Paper WM, for sway.

# SYNOPSIS

*spatial*

# DESCRIPTION

Spatial Shell is a daemon implementing a spatial model inspired by Material
Shell, but for sway.

Windows in Spatial Shell are placed on ribbons (one per workspace). The user
decides how many windows are displayed on screen at the same time, and can
unroll the ribbon in one direction or the user by focusing new windows
(horizontally). Besides, Spatial Shell also allows to move vertically from one
workspace to the other.

The most straightforward way to run Spatial Shell is via sway.

```
set $spatial /path/to/spatial
exec $spatial
```

Similarly, assigning bindings to interact with Spatial Shell is best done using
sway.

```
set $spatialmsg /path/to/spatialmsg
bindsym $mod+h exec $spatialmsg "focus left"
bindsym $mod+l exec $spatialmsg "focus right"
bindsym $mod+k exec $spatialmsg "focus up"
bindsym $mod+j exec $spatialmsg "focus down"
```

For information about the commands which can be sent to Spatial Shell via
*spatialmsg*(1), see *spatial*(5).

# LAYOUTS

In Spatial Shell, workspaces can use one of two modes: _maximize_ and _column_.
Each layout determines the strategy to display and organize the windows of the
workspace.

- *Maximize:* The focused window takes up the whole workspace.
- *Column:* Up to a fix number of windows are displayed on the workspace, the
  rest is hidden.

# CONFIGURATION

Spatial Shell searches for a config file in $XDG_CONFIG_HOME/spatial/config. If
$XDG_CONFIG_HOME is unset, it defaults to $HOME/.config.

The config file of Spatial Shell is a list of commands (one per line). See
*spatial*(5) for information about supported commands.

# IPC COMMANDS

Though *spatialmsg*(1) is generally preferred, you may interact with Spatial
Shell directly via IPC, see *spatial-ipc*(7).

The socket created by Spatial Shell is $XDG_RUNTIME_DIR/spatial.sock. If
$XDG_RUNTIME_DIR defaults to /tmp, that is the socket is /tmp/spatial.sock.

# ENVIRONMENT

The following environment variables have an effect on Spatial Shell.

_SWAYSOCK_
	Specifies the path to the socket Spatial Shell will connect to in order
	to interact with sway.

_XDG_CONFIG_HOME_
	If set, tells Spatial Shell where to find its config file. If unset,
	its values is defaulted to $HOME/.config.

_XDG_RUNTIME_DIR_
	If set, tells Spatial Shell where to create the socket other tools can
	use to control it. If unset, defaults to /tmp. For more information,
	see section *IPC COMMANDS*.

# AUTHOR

Developed by Thomas Letan <lthms@soap.coffee>. Fore more information about
Spatial Shell development, see <https://github.com/lthms/spatial-shell>.

# ACKNOWLEDGMENT

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
