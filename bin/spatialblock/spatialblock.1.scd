spatialblock(1)

# NAME

spatialblock - Generate contents for status bar blocks compatible with i3blocks
format.

# SYNOPSIS

spatialblock config++
spatialblock workspace <n>++
spatialblock window <n>

# DESCRIPTION

*spatialblock* is a simple program which can be used to populate a status bar
compatible with blocks about the current state of *spatial*(1). Its output
satisfies the *i3blocks*(1) format.

*spatialblock* can be configured to associate icons to application ids
(typically using a font like Font Awesome or from the Nerd Font family).

# COMMANDS

*config*
	Output the layout of the current workspace (see *spatial*(1)).

*workspace* <n>
	Output the icon of the window currently focused in the workspace _n_.
	Associate the class _focus_ to the block if the workspace _n_ is
	currently focused, and _unfocus_ otherwise.

*window* <n>
	Output the icon of the _n_ th window of the current workspace.
	Associate the class _focus_ to the block if the window is currently
	focused, and _unfocus_ otherwise.

# CONFIGURATION

*spatialblock* searches for a config file located at
$XDG_CONFIG_HOME/spatial/spatialblock.json. If $XDG_CONFIG_HOME is unset, it
defaults to $HOME/.config.

The config file of *spatialblock* is a JSON array containing objects with two
field: _app_id_ and _icon_. For instance,

```
[
  { "app_id": "firefox", "icon": "" },
  { "app_id": "kitty", "icon": "" },
  { "app_id": "Slack", "icon": "" },
  { "app_id": "emacs", "icon": "" },
  { "app_id": "neovide", "icon": "" },
  { "app_id": "chromium", "icon": "" }
]
```

# ENVIRONMENT

The following environment variables have an effect on Spatial Shell.

_XDG_CONFIG_HOME_
	If set, tells Spatial Shell where to find its config file. If unset,
	its values is defaulted to $HOME/.config.

# AUTHOR

Developed by Thomas Letan <lthms@soap.coffee>. Fore more information about
Spatial Shell development, see <https://github.com/lthms/spatial-shell>.

# ACKNOWLEDGMENT

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
