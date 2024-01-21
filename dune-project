(lang dune 3.0)
(name spatial-shell)

(generate_opam_files true)

(source
 (github lthms/spatial-shell))

(license mpl-2.0)

(authors "Thomas Letan <lthms@soap.coffee>")

(maintainers "Thomas Letan <lthms@soap.coffee>")

(version 7-dev)

(package
 (name spatial-shell)
 (synopsis
  "Implementing a spatial model inspired by Material Shell, for i3 and Sway")
 (depends (ocaml (>= "4.08")) poll (cmdliner (>= "1.2.0")) (ezjsonm-encoding (>= "2.0.0")) conf-scdoc))

(package
 (allow_empty)
 (name spatial-dev)
 (synopsis
  "Virtual package gathering developers dependencies for hacking the Spatial Shell project")
 (depends
  dune-release
  ocaml-lsp-server
  odoc
  (ocamlformat
   (= 0.26.1))))
