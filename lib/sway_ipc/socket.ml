(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Sway_ipc_types

type socket = Lwt_io.input_channel * Lwt_io.output_channel * Lwt_unix.file_descr

let sway_sock_path () =
  match Sys.getenv_opt "SWAYSOCK" with
  | Some path -> path
  | None -> failwith "SWAYSOCK environment variable is missing"

let rec read_all ~count ((socket, _, _) as s) =
  let open Lwt.Syntax in
  let* payload = Lwt_io.read ~count socket in
  if String.length payload = count then Lwt.return payload
  else
    let+ rest = read_all ~count:(count - String.length payload) s in
    payload ^ rest

let read_magic_string socket =
  let open Lwt.Syntax in
  let magic = Raw_message.magic_string in
  let* msg = read_all ~count:(String.length magic) socket in
  assert (msg = magic);
  Lwt.return ()

let write_raw_message (_, socket, _) raw =
  let msg = Raw_message.to_string raw in
  Lwt_io.write socket msg

let read_raw_message socket =
  let open Lwt.Syntax in
  let* () = read_magic_string socket in
  let* msg = read_all ~count:4 socket in
  let size = Raw_message.string_to_int32 msg in
  let* msg = read_all ~count:4 socket in
  let msg_type = Raw_message.string_to_int32 msg in
  let* payload = read_all ~count:(Int32.to_int size) socket in
  Lwt.return (msg_type, payload)

let rec read_next_event s evs =
  let open Lwt.Syntax in
  let* ((opc, _) as raw) = read_raw_message s in
  if List.exists (fun x -> opc = Sway_ipc_types.Event.event_type_code x) evs
  then Lwt.return (Event.event_of_raw_message raw)
  else read_next_event s evs

let close (_, _, s) = Lwt_unix.close s
