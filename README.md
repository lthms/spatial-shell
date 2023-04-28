# Spatial Shell

Spatial Shell implements a spatial model inspired by Material Shell and Paper
WM, for Sway. More precisely, it organizes the windows in your workspaces as if
they are on a ribbon, showing only a fixed number at a time.

It is implemented as a daemon, communicating with Sway using your favorite
tiling manager’s IPC protocol (if you are curious, have a look at `man
sway-ipc`!).

## Installing From Source

You will need `opam`.

```bash
# install dependencies
make build-deps
# install spatial
make install
```

In addition to the `spatial` and `spatialmsg` executables, this command
installs several man pages: `spatial(1)`, `spatialmsg(1)`, `spatial(5)`, and
`spatial-ipc(7)`.

If you want to hack Spatial Shell, you can install common development
dependencies with `make build-dev-deps`.

# Acknowledgement

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.
