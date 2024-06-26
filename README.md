# Spatial Shell

Spatial Shell is a daemon implementing a spatial model inspired by [Material
Shell][material-shell], for [i3][i3] and [sway][sway]. More precisely, it
organizes your windows within a grid whose rows are the workspaces of your
favorite WM.

https://github.com/lthms/spatial-shell/assets/1141231/2e5a77d0-c1f1-4cba-a9a1-6604de13bbfe

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

## Installation

### Building from Source

You will need `opam`.

If dynamically linked binaries are fine for your use case, then
building and installing Spatial Shell is as simple as the following.

```bash
# install dependencies
make build-deps
# might be unnecessary depending on your setup. If you are not familiar with
# OCaml and Opam, you probably need it.
eval $(opam env)
# build
make
# install spatial
make install
```

> [!IMPORTANT]
> By default, `make install` installs the files in `$HOME/.local`. As a
> consequence, Spatial Shell binaries might not be available in your `PATH` out
> of the box, especially if starting your graphic session from a display
> manager. A good alternative is to install in `/usr/local`.
>
> ```bash
> DESTDIR=/usr/local make install
> ```
>
> You will probably need to run this command as `root`.

If you want to hack Spatial Shell, you can install common development
dependencies with `make build-dev-deps`.

### Building Static Binaries from Source

Alternatively, you might want to build statically linked binaries for Spatial
Shell.

```bash
# If you have already created a local opam switch for Spatial Shell, remove it.
opam switch remove .
# You need a particular version of the OCaml compiler with no dependencies to
# zstd (unused by Spatial Shell) and using muslc instead of glibc.
OCAML_COMPILER=ocaml-option-static,ocaml-option-no-compression,ocaml.5.1.1 make build-deps
# You have to use the `static` profile to build.
BUILD_PROFILE=static make
# You can use DESTDIR to choose where the binaries and manpages are installed.
# See the note in the previous section.
make install
```

### Archlinux User Repository

Spatial Shell has been packages for Archlinux (see the [AUR
package][aur]).

For instance, if you have [Yay][yay] available, you can install Spatial Shell
with the following command.

```
yay -S spatial-shell
```

### Official Binary Builds

Starting with Spatial Shell 5th release, binary builds are attached to GitHub
releases for Linux (x86_64).

Signatures are provided as well. The maintainer public key is
[`320E11CB5316864648593D5E14CD43A3866E4C18`][pubkey].

## Getting Started

In addition to the `spatial`, `spatialmsg` and `spatialblock` executables, this
command installs several man pages: [`spatial(1)`][spatial.1],
[`spatialmsg(1)`][spatialmsg.1], [`spatialblock(1)`][spatialblock.1],
[`spatial(5)`][spatial.5], and [`spatial-ipc(7)`][spatial-ipc.7].

Spatial Shell is primilarly documented via these manpages.

### Configuring Your Favorite WM

At its core, Spatial Shell consists in a daemon (`spatial`) and a client
(`spatialmsg`) communicating with a IPC protocol. The most straightforward way
to run Spatial Shell daemon is via your favorite WM configuration file.

```
# Assuming `spatial` is available from $PATH
exec spatial
```

Once `spatial` is running, you can assign bindings to interact with it using
`spatialmsg` as part of the configuration of your favorite WM.

```
# Assuming `spatialmsg` is available from $PATH
bindsym $mod+h exec $spatialmsg "focus left"
bindsym $mod+l exec $spatialmsg "focus right"
bindsym $mod+k exec $spatialmsg "focus up"
bindsym $mod+j exec $spatialmsg "focus down"
```

For more information about the commands (including their exact syntax) which
can be sent to `spatial` via `spatialmsg`, see [`spatial(5)`][spatial.5]. 

This repositor also includes a [minimal configuration example][min-config] that
you can use to quickly setup Spatial Shell.

### Configuring Spatial Shell

Spatial Shell searches for a config file in `$XDG_CONFIG_HOME/spatial/config`.
If `$XDG_CONFIG_HOME` is unset, it defaults to `$HOME/.config`.

The config file of Spatial Shell is a list of commands (one per line).
Additionally, a line starting with a `#` is ignored (but inline comments are
not supported, that is, it is not possible to add a comment at the end of a
valid command).

See [`spatial(5)`][spatial.5] for information about supported commands.

### Configuring Your Favorite Status Bar

Spatial Shell is a lot more enjoyable to use with some visual aids to help you
visualize the state of the grid. To that end, spatial can be configured to send
a signal (`SIGMIN+8`) to a status bar everytime the configuration of the grid
changes (that is when the focus or the order of the windows changes).

spatial uses `pkill` to send the signal, and does so only when it has been
provided the name of the status bar program with the `status_bar_name` command.
For instance, assuming you are using [Waybar][waybar], add this line to your
Spatial Shell config file.

```
status_bar_name "waybar"
```

This repository includes examples of configuration for several status bar in
the [`contrib/` directory][contrib-dir]. These examples use `spatialblock`, a utility program
connecting directly to spatial socket (instead of relying on `spatialmsg`) in
order to reduce latency.

## Community

If you want to help build a nice community of hackers working on and users
enjoying Spatial Shell, you can use one of these mediums.

- [`r/spatialshell`][reddit] on Reddit
- [#spatial-shell][irc] on [Libera.Chat][libera]

## Acknowledgement

Spatial Shell could not have been possible without sway, which remains a
reference and a significant source of inspiration for the software architecture
of this project, including for the wording of several man pages.

[material-shell]: https://material-shell.com/
[i3]: https://i3wm.org/
[sway]: https://swaywm.org/
[spatial.1]: https://spatial-shell.app/spatial.1.html
[spatialmsg.1]: https://spatial-shell.app/spatialmsg.1.html
[spatialblock.1]: https://spatial-shell.app/spatialblock.1.html
[spatial.5]: https://spatial-shell.app/spatial.5.html
[spatial-ipc.7]: https://spatial-shell.app/spatial-ipc.7.html
[aur]: https://aur.archlinux.org/packages/spatial-shell
[yay]: https://github.com/Jguer/yay
[min-config]: ./contrib/sway/spatial.conf
[waybar]: https://github.com/Alexays/Waybar
[contrib-dir]: ./contrib/
[pubkey]: https://soap.coffee/~lthms/files/lthms@soap.coffee.pub
[reddit]: https://www.reddit.com/r/spatialshell/
[irc]: irc://libera.chat/#spatial-shell
[libera]: https://libera.chat/
