# ocaml-worker-pool

ocamlfind ocamlc -o ./bin/child -thread -linkpkg -package lwt,lwt_ppx,lwt.unix child.ml
ocamlfind ocamlc -o ./bin/server -thread -linkpkg -package lwt,lwt_ppx,lwt.unix server.ml