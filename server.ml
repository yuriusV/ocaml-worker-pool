open Lwt.Infix
open Lwt_io

let port = 54321

let log_message journal_file message =
  Lwt_io.with_file ~mode:Lwt_io.Output journal_file (fun file ->
      Lwt_io.fprintf file "%s\n" message)

let rec manage_processes num_processes process_list journal_file =
  let alive_processes = List.filter Lwt_unix.waitpid_none process_list in
  let missing_processes = num_processes - List.length alive_processes in
  if missing_processes > 0 then
    let new_processes =
      List.init missing_processes (fun _ -> Lwt_process.exec ("./child", [||]))
    in
    Lwt_list.iter_p (fun proc ->
        let pid = Lwt_unix.pid_of_process proc in
        log_message journal_file ("Restarted process: " ^ string_of_int pid))
      new_processes >>= fun () ->
    manage_processes num_processes (alive_processes @ new_processes) journal_file
  else
    Lwt_unix.sleep 1. >>= fun () ->
    manage_processes num_processes alive_processes journal_file

let handle_client (ic, oc) journal_file =
  let rec keep_alive () =
    Lwt_io.read_line ic >>= fun msg ->
    if msg = "keep-alive" then
      log_message journal_file "Received keep-alive" >>= fun () ->
      Lwt_io.write_line oc "keep-alive" >>= keep_alive
    else
      keep_alive ()
  in
  keep_alive ()

let rec accept_connections server journal_file =
  Lwt_unix.accept server >>= fun (client, _) ->
  let ic = Lwt_io.of_fd ~mode:Input client in
  let oc = Lwt_io.of_fd ~mode:Output client in
  Lwt.async (fun () -> handle_client (ic, oc) journal_file);
  accept_connections server journal_file

let run_server num_processes journal_file =
  let sockaddr = Lwt_unix.ADDR_INET (Unix.inet_addr_of_string "127.0.0.1", port) in
  Lwt_unix.(socket PF_INET SOCK_STREAM 0) >>= fun server ->
  Lwt_unix.setsockopt server Lwt_unix.SO_REUSEADDR true;
  Lwt_unix.bind server sockaddr >>= fun () ->
  Lwt_unix.listen server 10;
  let process_list =
    List.init num_processes (fun _ -> Lwt_process.exec ("./child", [||]))
  in
  Lwt.join [
    accept_connections server journal_file;
    manage_processes num_processes process_list journal_file
  ]

let () =
  let num_processes = int_of_string Sys.argv.(1) in
  let journal_file = "journal.txt" in
  Lwt_main.run (run_server num_processes journal_file)
