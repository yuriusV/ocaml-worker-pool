# ocaml-worker-pool

## Prepare env:
opam init
opam switch create 4.14.0
opam switch 4.14.0
eval $(opam env)
opam install conf-libev lwt lwt_ppx


## Build:
ocamlfind ocamlc -o ./bin/child -thread -linkpkg -package lwt,lwt_ppx,lwt.unix child.ml
ocamlfind ocamlc -o ./bin/server -thread -linkpkg -package lwt,lwt_ppx,lwt.unix server.ml