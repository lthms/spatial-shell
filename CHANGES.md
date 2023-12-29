# 7 (unreleased)

# 6 (2023-12-29)

## `spatial`

- Fix workspaces not being correctly re-arranged on some occasions: when it had
  lost focus due to a window being moved to another workspace, or when one of
  its window had been closed while it was not focused.
- Introduce `status_bar_name <name>` command to specify which status bar to
  signal when the windows arrangement is updated (was previously hard-coded to
  waybar).
- Support i3.

## `spatialblock`

- Rewrite the helper in OCaml, to enjoy (way) better performances leading to a
  smoother UX.
- Allow to dynamically associate applications ids with icons using a dedicated
  configuration file (either `$XDG_CONFIG_HOME/spatial/spatialblock.json` or
  `$HOME/.config/spatial/spatialblock.json`).

# 5 (2023-12-27)

## `spatial`

- Fix windows flickering for real (hopefully, this is a long running issue to
  be honest).
- Provide the LICENSE file as part of the installation process.

# 4 (2023-12-27)

## `spatial`

- Drop support for emulating dimmed unfocused windows by changing the opacity
  of unfocused windows.
- Drop any form of background management.
- Fix windows flickering when hitting two shortcuts at once.

# 3 (2023-12-26)

## `spatial`

- Extend commands `focus` and `move` to support targeting a specific workspace.
- Fix focus on floating windows.
- Extend commands `background` to specify a mode for the background (either fit
  or fill).
- Add a basic support for comments in the config file. Line starting with the
  character # are ignored.

# 2 (2023-05-18)

## `spatial`

- Drop the dynamic linking dependency to GMP.
- Fix moving a window upward being able to make a window disappear if the
  current workspace is the upmost one.
- Fix windows sometimes disappearing from workspaces when moving the focus
  upward or downward.

## `spatialmsg`

- Drop the dynamic linking dependency to GMP.

# 1 (2023-04-29)

The first release of Spatial Shell establishes a strong foundation for the
project. Following in i3 and sway’s footsteps, it introduces a daemon
(`spatial`), a client (`spatialmsg`), and a IPC protocol for them to
communicate.

The spatial model implemented by `spatial` allows users to navigate a grid of
windows wherein workspaces are rows, and to alternate between two layouts
(Maximize, and Column).

This is described in depth in the man pages introduced in this release.
