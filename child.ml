open Lwt.Infix
open Lwt_io

let port = 54321

let rec send_alive oc =
  let delay = Random.float 15. +. 5. in
  Lwt_unix.sleep delay >>= fun () ->
  Lwt_io.write_line oc "i am alive" >>= fun () ->
  send_alive oc

let run_child () =
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string "127.0.0.1", port) in
  Lwt_unix.(socket PF_INET SOCK_STREAM 0) >>= fun client ->
  Lwt_unix.connect client sockaddr >>= fun () ->
  let ic = Lwt_io.of_fd ~mode:Input (Lwt_unix.unix_file_descr client) in
  let oc = Lwt_io.of_fd ~mode:Output (Lwt_unix.unix_file_descr client) in
  let stop_delay = Random.float 60. +. 60. in
  Lwt_unix.sleep stop_delay >>= fun () ->
  Lwt_unix.close client >>= fun () ->
  Lwt.return_unit
  >>= fun () ->
  let rec handle_server () =
    Lwt_io.read_line ic >>= fun msg ->
    Lwt_io.write_line oc ("keep-alive " ^ string_of_int (String.length msg))
    >>= handle_server
  in
  Lwt.catch
    (fun () -> Lwt.join [handle_server (); send_alive oc])
    (fun ex -> Lwt_io.printl ("Error: " ^ Printexc.to_string ex))

let () = Lwt_main.run (run_child ())
