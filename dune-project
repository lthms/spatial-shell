(lang dune 3.0)

(generate_opam_files true)

(source
 (github lthms/spatial-shell))

(license mpl-2.0)

(authors "Thomas Letan <lthms@soap.coffee>")

(maintainers "Thomas Letan <lthms@soap.coffee>")

(version 5-dev)

(package
 (name spatial-shell)
 (synopsis
  "Implementing a spatial model inspired by Material Shell and Paper WM, for Sway")
 (depends poll clap ezjsonm))

(package
 (allow_empty)
 (name spatial-dev)
 (synopsis
  "Virtual package gathering developers dependencies for hacking the Spatial Shell project")
 (depends
  ocaml-lsp-server
  odoc
  (ocamlformat
   (= 0.25.1))))
