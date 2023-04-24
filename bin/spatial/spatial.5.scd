spatial(5)

# NAME

spatial - configuration file and commands

# DESCRIPTION

A Spatial Shell configuration file is a list of commands that are executed by
Spatial Shell on startup. These commands usually consist of setting your
preferences, either globally or per workspace.

# COMMANDS

This section lists the commands supported by Spatial Shell, which can be used in
the config file, via *spatialmsg*(1) or via *spatial-ipc*(7) directly.

*window* <n>
	Focus the *n*th window of the current workspace (starting from 0).

*focus* left|right|up|down
	Change the focus of sway to a new container, following the gride
	maintained by Spatial Shell. *focus right* and *focus left* move the
	focus horizontally, within a given workspace, while *focus up* and
	*focus down* move the focus vertically, from one workspace to the other.

*move* left|right|up|down
	Move the focused window within Spatial Shell gride, that is within its
	current ribbon (left or right) or to a different workspace (up or
	down). This command will change the current workspace in the latter
	case, so that the focused window remains focus.

*background* "<path>"
	Specifies the path of the background image. Spatial Shell relies on
	*swaybg*(1) to display said image, and therefore only supports image
	formats handled by *swaybg*.

*default layout* maximize|column++
*[workspace=*<n>*] default layout* maximize|column
	Set the default layout used by workspaces when they are first visited.
	See *spatial*(1) for a description of each layout.

*toggle layout*
	Change the layout of the current workspace. If the workspace was using
	the layout _Maximize_, then it switches to _Column_. On the contrary, if
	it was using the layout _Column_, then it switches to _Maximize_.

*default column count* <m>++
*[workspace=*<n>*] default column count* <m>
	Set the default number of windows displayed at most when a workspace
	uses the _Column_ layout.

*column count* increment|decrement
	Increase (resp. decrease) the maximum number of windows Spatial Shell
	shows in the current workspace, when the latter uses the _Column_
	layout. Default is 2, but this can be changed using the *default column
	count* command (etiher globally or per workspace).

*unfocus opacity* <n>
	Set the opacity of unfocused window to *n*%, that is, *n* is required to
	be an integer between 0 and 100.

# AUTHOR

Developed by Thomas Letan <lthms@soap.coffee>. Fore more information about
Spatial Shell development, see <https://github.com/lthms/spatial-shell>.

# ACKNOWLEDGMENT

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
