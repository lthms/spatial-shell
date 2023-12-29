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

*focus* left|right|up|down|workspace <n>
	Change the focus of sway to a new container, following the gride
	maintained by Spatial Shell. *focus right* and *focus left* move the
	focus horizontally, within a given workspace, while *focus up* and
	*focus down* move the focus vertically, from one workspace to the other.
	Finally, *focus workspace n* move the focus to the workspace _n_.

*move* left|right|up|down|workspace <n>
	Move the focused window within Spatial Shell gride, that is within its
	current ribbon (left or right) or to a different workspace (up or down).
	This command will change the current workspace in the latter case,
	inserting the window on the right of the previously focused one.
	Finally, *move workspace n* move the window to the workspace _n_. In
	these two cases, the current workspace is updated accordingly, and the
	moved window retains the focus.

*default layout* maximize|column++
*[workspace=*<n>*] default layout* maximize|column
	Set the default layout used by workspaces when they are first visited.
	Using the *[workspace=*<n>*]* prefix, limit the scope of the command
	to workspace _n_. See *spatial*(1) for a description of each layout.

*toggle layout*
	Change the layout of the current workspace. If the workspace was using
	the layout _Maximize_, then it switches to _Column_. On the contrary, if
	it was using the layout _Column_, then it switches to _Maximize_.

*default column count* <m>++
*[workspace=*<n>*] default column count* <m>
	Set the default number of windows displayed at most when a workspace
	uses the _Column_ layout. Using the *[workspace=*<n>*]* prefix, limit
	the scope of the command to workspace _n_.

*column count* increment|decrement
	Increase (resp. decrease) the maximum number of windows Spatial Shell
	shows in the current workspace, when the latter uses the _Column_
	layout. Default is 2, but this can be changed using the *default column
	count* command (etiher globally or per workspace).

*status_bar_name* "<name>"
	Set the name of the status bar (quotes are mandatory). This is used by
	*spatial*(1) to send it a signal (_SIGMIN+8_) to update it (for
	instance, when windows are moved around or the focus changes).

# AUTHOR

Developed by Thomas Letan <lthms@soap.coffee>. Fore more information about
Spatial Shell development, see <https://github.com/lthms/spatial-shell>.

# ACKNOWLEDGMENT

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
