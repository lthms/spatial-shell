DESTDIR ?= ${HOME}/.local
OCAML_COMPILER ?= ocaml-system

.PHONY: build
build:
	@dune build --release bin/spatial/main.exe
	@dune build --release bin/spatialmsg/main.exe

.PHONY: build-contrib
build-contrib:
	@dune build --release contrib/waybar/main.exe

.PHONY: man-pages
man-pages:
	@dune build @man-pages

.PHONY: install
install: build man-pages
	@install -vD _build/default/bin/spatial/main.exe "${DESTDIR}/bin/spatial"
	@install -vD _build/default/bin/spatialmsg/main.exe "${DESTDIR}/bin/spatialmsg"
	@install -vD _build/default/bin/spatial/spatial.1 "${DESTDIR}/share/man/man1/spatial.1"
	@install -vD _build/default/bin/spatialmsg/spatialmsg.1 "${DESTDIR}/share/man/man1/spatialmsg.1"
	@install -vD _build/default/bin/spatial/spatial.5 "${DESTDIR}/share/man/man5/spatial.5"
	@install -vD _build/default/lib/spatial_ipc/spatial-ipc.7 "${DESTDIR}/share/man/man7/spatial-ipc.7"
	@install -vD LICENSE "${DESTDIR}/share/licenses/spatial/LICENSE"

.PHONY: install-contrib
install-contrib: build-contrib
	@install -vD _build/default/contrib/waybar/main.exe "${DESTDIR}/bin/spatialbar"

.PHONY: uninstall
uninstall:
	@rm -f "${DESTDIR}/bin/spatial" "${DESTDIR}/bin/spatialmsg" "${DESTDIR}/share/man/man1/spatial.1" \
	       "${DESTDIR}/share/man/man5/spatial.5" "${DESTDIR}/share/man/man1/spatialmsg.1" \
	       "${DESTDIR}/share/man/man7/spatial-ipc.7"
	@rm -rf "${DESTDIR}/share/licenses/spatial/"

.PHONY: build-deps
build-deps:
	@opam switch create . --no-install --packages "${OCAML_COMPILER}" --deps-only -y || true
	@opam pin spatial-shell . --no-action -y
	@opam install spatial-shell --deps-only -y

.PHONY: build-dev-deps
build-dev-deps: build-deps
	@opam pin spatial-dev . --no-action -y
	@opam install spatial-dev --deps-only -y

