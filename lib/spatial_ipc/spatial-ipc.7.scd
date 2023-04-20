spatial-ipc(7)

# NAME

spatial-ipc - IPC protocol for Spatial Shell

# DESCRIPTION

This man page describes the IPC protocol third-party tools can use to control or
obtain information from a Spatial Shell instance.

Similarly to *sway*(1), the IPC protocol uses a UNIX socket as the method of
communication. The path to the socket is $XDG_RUNTIME_DIR/spatial.sock, and if
$XDG_RUNTIME_DIR is unset, it defaults to $HOME/.config.

# MESSAGE AND REPLY FORMAT

The format for messages and replies is exactly the same as the one described in
*sway-ipc*(7).

# MESSAGES AND REPLIES

The following message types and their respective reply are currently supported.

[- *TYPE NUMBER*
:- *MESSAGE NAME*
:- *PURPOSE*
|-  0
:-  RUN_COMMAND
:[ Runs the payload as a Spatial Shell command
|- 1
:- GET_WINDOWS
:[ Get the list of windows of the current workspace
|- 2
:- GET_WORKSPACES
:[ Get the list of workspaces with at least one window.
|- 3
:- GET_WORKSPACE_CONFIG
:[ Get the configuration of the current workspace.

# 0. RUN_COMMAND

*MESSAGE*++
Runs the payload as a Spatial Shell command. See *spatial*(5) for a list of the
commands supported by Spatial Shell.

*REPLY*++
A JSON object with a _success_ boolean property to witness if the command has
been successfully parsed and interpreted by the Spatial Shell instance, or if
something went wrong.

*Examples of reply:*

```
{ "success": true }
```

```
{ "success": false }
```


# 1. GET_WINDOWS

*MESSAGE*++
Get the list of windows of the current workspace. No payload expected.

*REPLY*++
The reply of the *GET_WINDOWS* message is a JSON object with the following
properties.

[- *PROPERTY*
:- *TYPE*
:- *PURPOSE*
|- focus
:- integer
:[ The index of the window currently holding sway’s focus.
|- windows
:- list
:[ The list of windows managed by the current workspace.

A window is encoded as an object with the following properties.

[- *PROPERTY*
:- *TYPE*
:- *PURPOSE*
|- app_id
:- string
:[ The app_id of the window, as reported by sway.
|- name
:- string
:[ The name of the window, as maintained and reported by sway.

*Example of reply:*

```
{ "focus": 0,
  "windows":
    [ { "app_id": "kitty", "name": "zsh" },
      { "app_id": "firefox",
        "name":
          "Ubuntu Manpage: scdoc - document format for writing manual pages — Mozilla Firefox" } ] }
```

# 2. GET_WORKSPACES

*MESSAGE*++
Get the list of workspaces with at least one window. No payload expected.

*REPLY*++
The reply of the *GET_WORKSPACES* message is a JSON object with the following
properties.

[- *PROPERTY*
:- *TYPE*
:- *PURPOSE*
|- focus
:- integer
:[ The index of the workspace currently focused by sway.
|- workspaces
:- list
:[ The list of workspaces containing at least one window.

A workspace is encoded as an object with the following properties.

[- *PROPERTY*
:- *TYPE*
:- *PURPOSE*
|- index
:- int
:[ The position of the workspace in Spatial Shell’s gride.
|- focused_windows
:- window
:[ The description of the window currently holding the focus.

*Example of reply:*

```
{ "focus": 1,
  "workspaces":
    [ { "index": 1, "focused_window": { "app_id": "kitty", "name": "zsh" } },
      { "index": 3,
        "focused_window":
          { "app_id": "firefox",
            "name":
              "spatial-shell/spatialbar.py at main · lthms/spatial-shell · GitHub — Mozilla Firefox" } } ] }
```

# 3. GET_WORKSPACE_CONFIG

*MESSAGE*++
Get the configuration of the current workspace. No payload required.

*REPLY*

[- *PROPERTY*
:- *TYPE*
:- *PURPOSE*
|- layout
:- string
:[ Either _column_ or _maximize_.
|- column_count
:- int
:[ The maximum number of windows displayed by Spatial Shell when the layout is
       _column_.

*Example of reply:*

```
{ "layout": "column", "column_count": 2 }
```

# AUTHOR

Developed by Thomas Letan <lthms@soap.coffee>. Fore more information about
Spatial Shell development, see <https://github.com/lthms/spatial-shell>.

# ACKNOWLEDGMENT

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
