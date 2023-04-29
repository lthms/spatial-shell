DESTDIR ?= /usr/local

.PHONY: build
build:
	@dune build --release bin/spatial/main.exe
	@dune build --release bin/spatialmsg/main.exe

.PHONY: man-pages
man-pages:
	@dune build @man-pages

.PHONY: install
install: build man-pages
	@install -v _build/default/bin/spatial/main.exe "${DESTDIR}/bin/spatial"
	@install -v _build/default/bin/spatialmsg/main.exe "${DESTDIR}/bin/spatialmsg"
	@install -vD _build/default/bin/spatial/spatial.1 "${DESTDIR}/share/man/man1/spatial.1"
	@install -vD _build/default/bin/spatialmsg/spatialmsg.1 "${DESTDIR}/share/man/man1/spatialmsg.1"
	@install -vD _build/default/bin/spatial/spatial.5 "${DESTDIR}/share/man/man5/spatial.5"
	@install -vD _build/default/lib/spatial_ipc/spatial-ipc.7 "${DESTDIR}/share/man/man7/spatial-ipc.7"

.PHONY: uninstall
uninstall:
	@rm -f "${DESTDIR}/bin/spatial" "${DESTDIR}/bin/spatialmsg" "${DESTDIR}/share/man/man1/spatial.1" \
	       "${DESTDIR}/share/man/man5/spatial.5" "${DESTDIR}/share/man/man1/spatialmsg.1" \
	       "${DESTDIR}/share/man/man7/spatial-ipc.7"

.PHONY: build-deps
build-deps:
	@opam switch create . --no-install --packages "ocaml-base-compiler.5.0.0" --deps-only -y || true
	@opam pin spatial-shell . --no-action -y
	@opam install spatial-shell --deps-only -y

.PHONY: build-dev-deps
build-dev-deps: build-deps
	@opam pin spatial-dev . --no-action -y
	@opam install spatial-dev --deps-only -y

