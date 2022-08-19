let connect () =
  let open Lwt.Syntax in
  let socket = Lwt_unix.socket PF_UNIX SOCK_STREAM 0 in
  let+ () = Lwt_unix.connect socket (ADDR_UNIX Spatial_sway_ipc.socket_path) in
  socket

let send_command socket cmd =
  let open Lwt.Syntax in
  let buffer = Bytes.create 4 in
  Bytes.set_int32_ne buffer 0 (Spatial_sway_ipc.to_int32 cmd);
  let* _ = Lwt_unix.write socket buffer 0 4 in
  Lwt.return ()

let main () =
  let open Lwt.Syntax in
  let cmd =
    match Sys.argv.(1) with
    | "move_left" -> Spatial_sway_ipc.Move_left
    | "move_right" -> Move_right
    | "move_window_left" -> Move_window_left
    | "move_window_right" -> Move_window_right
    | "toggle_full_view" -> Toggle_full_view
    | "incr_maximum_visible_size" -> Incr_maximum_visible_space
    | "decr_maximum_visible_size" -> Decr_maximum_visible_space
    | _ -> raise (Invalid_argument "bad command")
  in
  let* socket = connect () in
  let* () = send_command socket cmd in
  Lwt_unix.close socket

let () = Lwt_main.run @@ main ()
