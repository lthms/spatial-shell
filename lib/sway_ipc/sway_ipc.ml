open Sway_ipc_types

let connect () =
  let open Lwt.Syntax in
  let socket = Lwt_unix.socket PF_UNIX SOCK_STREAM 0 in
  let+ () = Lwt_unix.connect socket (ADDR_UNIX (Socket.sway_sock_path ())) in
  let socket_in = Lwt_io.of_fd ~mode:Input socket in
  let socket_out = Lwt_io.of_fd ~mode:Output socket in
  (socket_in, socket_out, socket)

let close socket = Socket.close socket

let wtih_socket f =
  let open Lwt.Syntax in
  let* socket = connect () in
  let* res = f socket in
  let+ () = Socket.close socket in
  res

let socket_from_option = function
  | Some socket -> Lwt.return socket
  | None -> connect ()

let send_command ?socket cmd =
  let open Lwt.Syntax in
  let* socket = socket_from_option socket in
  let ((op, _) as raw) = Message.to_raw_message cmd in
  let* () = Socket.write_raw_message socket raw in
  let* op', payload = Socket.read_raw_message socket in
  assert (op = op');
  Lwt.return @@ Json_decoder.of_string (Message.reply_decoder cmd) payload

let subscribe ?socket events =
  let open Lwt.Syntax in
  let* socket = socket_from_option socket in
  let+ { success } = send_command ~socket (Subscribe events) in
  if success then
    Lwt_stream.from (fun () ->
        let+ ev = Socket.read_next_event socket events in
        Some ev)
  else failwith "Something went wrong"

let get_tree ?socket () = send_command ?socket Get_tree

let get_current_workspace ?socket () =
  let open Lwt.Syntax in
  let+ workspaces = send_command ?socket Get_workspaces in
  List.find (fun w -> w.Workspace.focused) workspaces
