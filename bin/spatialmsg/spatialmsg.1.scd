spatialmsg(1)

# NAME

spatialmsg - Send messages to a running instance of Spatial Shell over the IPC socket.

# SYNOPSIS

spatialmsg [options...] [message]

# OPTIONS

*--quiet*
	Sends the IPC message, but does not print the response from Spatial
	Shell.

*--json*
	Prints the response from Spatial Shell as received, that is in JSON.
*--type, -t <type>*
	Specify the type of the IPC message. See below.

# IPC MESSAGE TYPES

*<command>*
	The message is a Spatial Shell command. See *spatial*(5) for a list of
	available commands.

*get_workspace_config*
	Gets the current workspace configuration: its layout, and the maximum
	number of columns displayed at once when in the _column_ layout.

*get_workspaces*
	Gets the list of the workspaces currently in used.

*get_windows*
	Gets the list of the windows for the current workspace.

See *spatial-ipc*(7) for a description of the JSON objects returned for each IPC
message.


# RETURN CODE

0
	Success

1
	Invalid command line arguments

2
	Spatial Shell returned an error when

# AUTHOR

Developed by Thomas Letan <lthms@soap.coffee>. Fore more information about
Spatial Shell development, see <https://github.com/lthms/spatial-shell>.

# ACKNOWLEDGMENT

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
