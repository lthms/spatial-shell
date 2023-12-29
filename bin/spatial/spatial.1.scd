spatial(1)

# NAME

spatial - Implementing a spatial model inspired by Material Shell and Paper WM, for sway.

# SYNOPSIS

*spatial*

# DESCRIPTION

Spatial Shell is a daemon implementing a spatial model inspired by Material
Shell, for i3 and sway. More precisely, it organizes your windows within a grid
whose rows are the workspaces of your favorite WM.

In a nutshell, Spatial Shell allows you to:

- Move the focus within the grid: on the left or on the right within the current
  workspace, or on focused window of the upper or lower workspace. In the
  former case, the current workspace does not change, while in the latter it
  does.
- Move the focused window within the grid: to the left or to the right within
  the current workspace, or to the upper or lower workspace. In the former case,
  the focused windows is swapped with its neighbor, while in the former it is
  inserted at the right of the previously focused window within this row.
- Configure how many windows are displayed at most within a given workspace
  (for when the workspace uses the _column_ layout).
- Toggle between the *Column* and _maximize_ layout for the current workspace
  (see the *LAYOUT* section)

Spatial Shell consists in a daemon (*spatial*) and a client
(*spatialmsg*(1)) communicating with a IPC protocol (*spatial-ipc*(7)). The most
straightforward way to run Spatial Shell daemon is via your favorite WM
configuration file.

```
# Assuming `spatial` is available from $PATH
exec spatial
```

Once spatial is running, you can assign bindings to interact with it using
*spatialmsg*(1) as part of the configuration of your favorite WM

```
# Assuming `spatialmsg` is available from $PATH
bindsym $mod+h exec $spatialmsg "focus left"
bindsym $mod+l exec $spatialmsg "focus right"
bindsym $mod+k exec $spatialmsg "focus up"
bindsym $mod+j exec $spatialmsg "focus down"
```

For more information about the commands (including the exact syntax) which can
be sent to *spatial* via *spatialmsg*(1), see *spatial*(5). 

# LAYOUTS

In Spatial Shell, workspaces can use one of two modes: _maximize_ and _column_.
Each layout determines the strategy to display and organize the windows of the
workspace.

- *Maximize:* The focused window takes up the whole workspace.
- *Column:* Up to a fix number of windows are displayed on the workspace, the
  rest is hidden.

# CONFIGURATION

*spatial*(5) searches for a config file in $XDG_CONFIG_HOME/spatial/config. If
$XDG_CONFIG_HOME is unset, it defaults to $HOME/.config.

The config file of Spatial Shell is a list of commands (one per line).
Additionally, a line starting with a _#_ is ignored (but inline comments are not
supported, that is, it is not possible to add a comment at the end of a valid
command). See *spatial*(5) for information about supported commands.

Spatial Shell is a lot more enjoyable to use with some visual aids to help you
visualize the state of the grid. To that end, *spatial* can be configured to send
a signal (_SIGMIN+8_) to a status bar everytime the configuration of the grid
changes (that is when the focus or the order of the windows changes).

*spatial* uses *pkill*(1) to send the signal, and does so only when it has been
provided the name of the status bar program with the `status_bar_name` command.
For instance, assuming you are using *waybar*(5), add this line to your Spatial
Shell config file.

```
status_bar_name "waybar"
```

# IPC COMMANDS

Though *spatialmsg*(1) is generally preferred, you may interact with Spatial
Shell directly via IPC, see *spatial-ipc*(7). This is typically what
*spatialblock*(1) does to reduce latency as much as possible.

The socket created by Spatial Shell is $XDG_RUNTIME_DIR/spatial.sock. If
$XDG_RUNTIME_DIR defaults to /tmp, that is the socket is /tmp/spatial.sock.

# ENVIRONMENT

The following environment variables have an effect on Spatial Shell.

_SWAYSOCK_
	Specifies the path to the socket *spatial* will connect to in order to
	interact with sway. If unset, defaults to _I3SOCK_.

_I3SOCK_
	Specifies the path to the socket *spatial* will connect to in order to
	interact with i3, when _SWAYLOCK_ is unset. If required but unset,
	*spatial* will exit with an error.

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
