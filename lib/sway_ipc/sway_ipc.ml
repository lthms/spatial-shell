(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Sway_ipc_types
open Mltp_ipc

exception Sway_ipc_error of Socket.error

let magic_string = "i3-ipc"

let sway_sock_path () =
  match Sys.getenv_opt "SWAYSOCK" with
  | Some path -> path
  | None -> failwith "SWAYSOCK environment variable is missing"

type socket = Socket.socket

let connect () : socket Lwt.t = Socket.connect (sway_sock_path ())
let close socket = Socket.close socket

let trust_sway f =
  let open Lwt.Syntax in
  let* x = f () in
  match x with Ok x -> Lwt.return x | Error e -> raise (Sway_ipc_error e)

let with_socket f = Socket.with_socket (sway_sock_path ()) f

let socket_from_option = function
  | Some socket -> Lwt.return socket
  | None -> connect ()

let send_command ?socket cmd =
  let open Lwt.Syntax in
  let* socket = socket_from_option socket in
  let ((op, _) as raw) = Message.to_raw_message cmd in
  let* () =
    trust_sway @@ fun () -> Socket.write_raw_message ~magic_string socket raw
  in
  let* op', payload =
    trust_sway @@ fun () -> Socket.read_raw_message ~magic_string socket
  in
  assert (op = op');
  Lwt.return @@ Json_decoder.of_string_exn (Message.reply_decoder cmd) payload

let subscribe ?socket events =
  let open Lwt.Syntax in
  let* socket = socket_from_option socket in
  let+ { success } = send_command ~socket (Subscribe events) in
  if success then
    Lwt_stream.from (fun () ->
        let open Lwt.Syntax in
        let+ ev =
          Socket.read_next_raw_message ~magic_string socket (fun (code, _) ->
              List.exists
                (fun ev_type -> ev_type = Event.event_type_of_code code)
                events)
        in
        match ev with
        | Ok ev -> Some (Event.event_of_raw_message ev)
        | Error _ -> None)
  else failwith "Something went wrong"

let get_tree ?socket () = send_command ?socket Get_tree

let get_current_workspace ?socket () =
  let open Lwt.Syntax in
  let+ workspaces = send_command ?socket Get_workspaces in
  List.find (fun w -> w.Workspace.focused) workspaces
