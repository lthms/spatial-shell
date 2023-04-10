.PHONY: build
build:
	@dune build --release bin/spatial/main.exe
	@dune build --release bin/spatialmsg/main.exe

.PHONY: install
install: build
	@sudo -k
	@sudo install -v _build/default/bin/spatial/main.exe /usr/local/bin/spatial
	@sudo install -v _build/default/bin/spatialmsg/main.exe /usr/local/bin/spatialmsg

.PHONY: uninstall
uninstall:
	@sudo -k
	@rm -f /usr/local/bin/spatial /usr/local/bin/spatialmsg

.PHONY: build-deps
build-deps:
	@opam switch create . ocaml-base-compiler.5.0.0 --deps-only

