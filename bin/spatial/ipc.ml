open Spatial_sway_ipc

let rec socket_handler server () =
  let open Lwt.Syntax in
  let* socket, _ = Lwt_unix.accept server in
  let buffer = Bytes.create 4 in
  try
    let* read_bytes = Lwt_unix.read socket buffer 0 4 in
    assert (read_bytes = 4);
    let code = Bytes.get_int32_ne buffer 0 in
    let* () = Lwt_unix.close socket in
    Lwt.return @@ Some (of_int32_exn code)
  with _ ->
    let* () = Lwt_unix.close socket in
    socket_handler server ()

let create_server () =
  let open Lwt.Syntax in
  let socket = Lwt_unix.socket PF_UNIX SOCK_STREAM 0 in
  let* socket_exists = Lwt_unix.file_exists socket_path in
  let* () =
    if socket_exists then Lwt_unix.unlink socket_path else Lwt.return ()
  in
  let sockaddr = Lwt_unix.ADDR_UNIX socket_path in
  let+ () = Lwt_unix.bind socket sockaddr in
  let () = Lwt_unix.listen socket 100 in
  Lwt_stream.from (socket_handler socket)
