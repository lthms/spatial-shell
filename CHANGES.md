# Spatial Shell Changelog

## Release 2 (2023-05-18)

### `spatial`

- Drop the dynamic linking dependency to GMP.
- Fix moving a window upward being able to make a window disappear if the
  current workspace is the upmost one.
- Fix windows sometimes disappearing from workspaces when moving the focus
  upward or downward.

### `spatialmsg`

- Drop the dynamic linking dependency to GMP.

## Release 1 (2023-04-29)

The first release of Spatial Shell establishes a strong foundation for the
project. Following in i3 and sway’s footsteps, it introduces a daemon
(`spatial`), a client (`spatialmsg`), and a IPC protocol for them to
communicate.

The spatial model implemented by `spatial` allows users to navigate a grid of
windows wherein workspaces are rows, and to alternate between two layouts
(Maximize, and Column).

This is described in depth in the man pages introduced in this release.
