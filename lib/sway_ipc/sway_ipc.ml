(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Sway_ipc_types
open Mltp_ipc

let magic_string = "i3-ipc"

let sway_sock_path () =
  match Sys.getenv_opt "SWAYSOCK" with
  | Some path -> path
  | None -> failwith "SWAYSOCK environment variable is missing"

type socket = Socket.socket

let connect () = Socket.connect (sway_sock_path ())
let close socket = Socket.close socket

let with_socket ?socket f =
  match socket with
  | Some socket -> f socket
  | None -> Socket.with_socket (sway_sock_path ()) f

let send_command : type a. ?socket:socket -> a Message.t -> a =
 fun ?socket cmd ->
  with_socket ?socket @@ fun socket ->
  let ((op, _) as raw) = Message.to_raw_message cmd in
  Socket.write_raw_message ~magic_string socket raw;
  let op', payload = Socket.read_raw_message ~magic_string socket in
  assert (op = op');
  Jsoner.Decoding.of_string_exn (Message.reply_decoder cmd) payload

let subscribe events =
  let socket = connect () in
  let ({ success } : Message.subscribe_reply) =
    send_command ~socket (Subscribe events)
  in
  if success then socket else failwith "could not subscribe"

let read_event socket =
  let raw = Socket.read_next_raw_message ~magic_string socket (fun _ -> true) in
  Event.event_of_raw_message raw

let get_tree ?socket () = send_command ?socket Get_tree

let get_current_workspace ?socket () =
  let workspaces = send_command ?socket Get_workspaces in
  List.find (fun w -> w.Workspace.focused) workspaces

let send_tick ?socket payload = send_command ?socket (Send_tick payload)
