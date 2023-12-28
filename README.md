# Spatial Shell

Spatial Shell implements a spatial model inspired by Material Shell and Paper
WM, for i3 and Sway. More precisely, it organizes the windows in your
workspaces as if they are on a ribbon, showing only a fixed number at a time.

It is implemented as a daemon, communicating with i3 or Sway using your
favorite tiling manager’s IPC protocol (if you are curious, have a look at `man
sway-ipc`!).

## Configuration

The simplest way to start using Spatial Shell with sway is to include the
minimal configuration file provided in this repository
(`contrib/sway/spatial.conf`) in your i3 or sway config file. You will need to set
some variables before including it.

Spatial Shell is a lot more enjoyable to use with some visual aids to help you
visualize the state of the grid. You can find an example configuration for
[Waybar](https://github.com/Alexays/Waybar) in `contrib/waybar` that works out
of the box with Spatial Shell. This configuration relies on `spatialblock`,
a small utility program which can be used with any status bar compatible with
`i3blocks` format.

## Installation

### Building from Source

You will need `opam`.

```bash
# install dependencies
make build-deps
# install spatial
make install
```

In addition to the `spatial`, `spatialmsg` and `spatialblock` executables, this
command installs several man pages: `spatial(1)`, `spatialmsg(1)`,
`spatialblock(1)`, `spatial(5)`, and `spatial-ipc(7)`.

If you want to hack Spatial Shell, you can install common development
dependencies with `make build-dev-deps`.

### Archlinux User Repository

Spatial Shell has been packages for Archlinux (see the [AUR
package](https://aur.archlinux.org/packages/spatial-shell)).

For instance, if you have [`yay`](https://github.com/Jguer/yay) available,
you can install Spatial Shell with the following command.

```
yay -S spatial-shell
```

# Acknowledgement

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
