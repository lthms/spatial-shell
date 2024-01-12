DESTDIR ?= ${HOME}/.local
OCAML_COMPILER ?= ocaml-system
BUILD_PROFILE ?= release

.PHONY: all
all: build man-pages

.PHONY: build
build:
	@dune build --profile=${BUILD_PROFILE} bin/spatial/main.exe
	@dune build --profile=${BUILD_PROFILE} bin/spatialmsg/main.exe
	@dune build --profile=${BUILD_PROFILE} bin/spatialblock/main.exe

.PHONY: man-pages
man-pages:
	@dune build @man-pages

.PHONY: install
install:
	@install -vD _build/default/bin/spatial/main.exe "${DESTDIR}/bin/spatial"
	@install -vD _build/default/bin/spatialmsg/main.exe "${DESTDIR}/bin/spatialmsg"
	@install -vD _build/default/bin/spatialblock/main.exe "${DESTDIR}/bin/spatialblock"
	@install -vD _build/default/bin/spatial/spatial.1 "${DESTDIR}/share/man/man1/spatial.1"
	@install -vD _build/default/bin/spatialmsg/spatialmsg.1 "${DESTDIR}/share/man/man1/spatialmsg.1"
	@install -vD _build/default/bin/spatialblock/spatialblock.1 "${DESTDIR}/share/man/man1/spatialblock.1"
	@install -vD _build/default/bin/spatial/spatial.5 "${DESTDIR}/share/man/man5/spatial.5"
	@install -vD _build/default/lib/spatial_ipc/spatial-ipc.7 "${DESTDIR}/share/man/man7/spatial-ipc.7"
	@install -vD LICENSE "${DESTDIR}/share/licenses/spatial/LICENSE"

.PHONY: uninstall
uninstall:
	@rm -f "${DESTDIR}/bin/spatial" "${DESTDIR}/bin/spatialmsg" "${DESTDIR}/bin/spatialblock" \
	       "${DESTDIR}/share/man/man1/spatial.1" \ "${DESTDIR}/share/man/man5/spatial.5" \
	       "${DESTDIR}/share/man/man1/spatialmsg.1" "${DESTDIR}/share/man/man1/spatialblock.1" \
	       "${DESTDIR}/share/man/man7/spatial-ipc.7"
	@rm -rf "${DESTDIR}/share/licenses/spatial/"

_opam/.created:
	@opam switch create . --no-install --packages "${OCAML_COMPILER}" --deps-only -y || true
	@touch $@

.PHONY: build-deps
build-deps: _opam/.created
	@opam update
	@opam pin spatial-shell . --no-action -y
	@opam install spatial-shell --deps-only -y

.PHONY: build-dev-deps
build-dev-deps: _opam/.created
	@opam update
	@opam pin spatial-shell . --no-action -y
	@opam pin spatial-dev . --no-action -y
	@opam install spatial-shell spatial-dev --deps-only -y

# Disable parallel execution to ensure we don’t invoke `dune' in parallel.
.NOTPARALLEL:
