.PHONY: build-deps
build-deps:
	@opam switch create . ocaml-base-compiler.5.0.0 --deps-only

