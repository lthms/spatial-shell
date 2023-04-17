(lang dune 3.0)

(generate_opam_files true)

(source
 (github lthms/spatial))

(license mpl-2.0)

(authors "Thomas Letan <lthms@soap.coffee>")

(maintainers "Thomas Letan <lthms@soap.coffee>")

(package
 (name miam)
 (synopsis "A parser combinator library, inspired by nom"))

(package
 (name json-decoder)
 (synopsis "A la data-encoding JSON decoder allowing input supersets")
 (depends ezjsonm))

(package
 (name mltp-ipc)
 (synopsis
  "Generic messaging over IPC library, inspired by i3/Sway length-type-payload encoding"))

(package
 (name sway-ipc)
 (synopsis "Interacting with Sway through IPC")
 (depends json-decoder mltp-ipc))

(package
 (name spatial)
 (synopsis
  "Implementing a spatial model inspired by Material Shell and Paper WM, for Sway.")
 (depends data-encoding poll sway-ipc clap miam))

(package
 (allow_empty)
 (name spatial-dev)
 (synopsis
  "Virtual package gathering developers dependencies for hacking the spatial project")
 (depends
  ocaml-lsp-server
  odoc
  (ocamlformat
   (= 0.25.1))))
