(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type socket = Lwt_io.input_channel * Lwt_io.output_channel * Lwt_unix.file_descr
type error = Bad_magic_string of string | Connection_closed

let ( let*! ) x k = Lwt.bind x k

let connect socket_path : socket Lwt.t =
  let open Lwt.Syntax in
  let socket = Lwt_unix.socket PF_UNIX SOCK_STREAM 0 in
  let+ () = Lwt_unix.connect socket (ADDR_UNIX socket_path) in
  let socket_in = Lwt_io.of_fd ~mode:Input socket in
  let socket_out = Lwt_io.of_fd ~mode:Output socket in
  (socket_in, socket_out, socket)

let close (_, _, s) = Lwt_unix.close s

let with_socket socket_path f =
  let open Lwt.Syntax in
  let* socket = connect socket_path in
  Lwt.try_bind
    (fun () ->
      let* res = f socket in
      let* () = close socket in
      Lwt.return res)
    Lwt.return
    (fun exn ->
      let* () = close socket in
      raise exn)

let catch_end_of_file f =
  Lwt.try_bind f Lwt_result.return @@ function
  | End_of_file -> Lwt_result.fail Connection_closed
  | exn -> Lwt.fail exn

let rec read_all ~count ((socket, _, _) as s) =
  let open Lwt_result.Syntax in
  let* payload = catch_end_of_file (fun () -> Lwt_io.read ~count socket) in
  if String.length payload = count then Lwt_result.return payload
  else
    let+ rest = read_all ~count:(count - String.length payload) s in
    payload ^ rest

let read_magic_string ~magic_string socket =
  let open Lwt_result.Syntax in
  let* msg = read_all ~count:(String.length magic_string) socket in
  if msg <> magic_string then
    let*! () = close socket in
    Lwt_result.fail (Bad_magic_string msg)
  else Lwt_result.return ()

let write_raw_message ~magic_string (_, socket, _) raw =
  let msg = Raw_message.to_string ~magic_string raw in
  catch_end_of_file @@ fun () -> Lwt_io.write socket msg

let read_raw_message ~magic_string socket =
  let open Lwt_result.Syntax in
  let* () = read_magic_string ~magic_string socket in
  let* msg = read_all ~count:4 socket in
  let size = Raw_message.string_to_int32 msg in
  let* msg = read_all ~count:4 socket in
  let msg_type = Raw_message.string_to_int32 msg in
  let* payload = read_all ~count:(Int32.to_int size) socket in
  Lwt_result.return (msg_type, payload)

let rec read_next_raw_message ~magic_string socket f =
  let open Lwt_result.Syntax in
  let* raw = read_raw_message ~magic_string socket in
  if f raw then Lwt_result.return raw
  else read_next_raw_message ~magic_string socket f
