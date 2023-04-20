.PHONY: build
build:
	@dune build --release bin/spatial/main.exe
	@dune build --release bin/spatialmsg/main.exe

.PHONY: man-pages
man-pages:
	@dune build @man-pages

.PHONY: install
install: build man-pages
	@sudo -k
	@sudo install -v _build/default/bin/spatial/main.exe /usr/local/bin/spatial
	@sudo install -v _build/default/bin/spatialmsg/main.exe /usr/local/bin/spatialmsg
	@sudo install -vD _build/default/bin/spatial/spatial.1 /usr/local/man/man1/spatial.1
	@sudo install -vD _build/default/bin/spatialmsg/spatialmsg.1 /usr/local/man/man1/spatialmsg.1
	@sudo install -vD _build/default/bin/spatial/spatial.5 /usr/local/man/man5/spatial.5
	@sudo install -vD _build/default/lib/spatial_ipc/spatial-ipc.7 /usr/local/man/man7/spatial-ipc.7

.PHONY: uninstall
uninstall:
	@sudo -k
	@sudo rm -f /usr/local/bin/spatial /usr/local/bin/spatialmsg /usr/local/man/man1/spatial.1 \
	            /usr/local/man/man5/spatial.5 /usr/local/man/man1/spatialmsg.1

.PHONY: build-deps
build-deps:
	@opam switch create . ocaml-base-compiler.5.0.0 --deps-only

