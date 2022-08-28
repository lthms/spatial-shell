(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type socket = Unix.file_descr

exception Bad_magic_string of string
exception Connection_closed

let connect socket_path : socket =
  let socket = Unix.socket PF_UNIX SOCK_STREAM 0 in
  let () = Unix.connect socket (ADDR_UNIX socket_path) in
  socket

let close s = Unix.close s

let with_socket socket_path f =
  let socket = connect socket_path in
  try
    let res = f socket in
    close socket;
    res
  with exn ->
    close socket;
    raise exn

let read_all ~count s =
  let buffer = Bytes.create count in
  let rec aux ~left =
    let read = Unix.read s buffer (count - left) left in
    if read = 0 then raise End_of_file;
    let remainder = left - read in
    if remainder = 0 then buffer else aux ~left:remainder
  in
  aux ~left:count |> Bytes.to_string

let read_magic_string ~magic_string socket =
  let msg = read_all ~count:(String.length magic_string) socket in
  if msg <> magic_string then (
    close socket;
    raise (Bad_magic_string msg))

let write_raw_message ~magic_string s raw =
  try
    let msg = Raw_message.to_string ~magic_string raw in
    let _ = Unix.write_substring s msg 0 (String.length msg) in
    ()
  with
  | End_of_file -> raise Connection_closed
  | exn ->
      close s;
      raise exn

let read_raw_message ~magic_string socket =
  try
    read_magic_string ~magic_string socket;
    let msg = read_all ~count:4 socket in
    let size = Raw_message.string_to_int32 msg in
    let msg = read_all ~count:4 socket in
    let msg_type = Raw_message.string_to_int32 msg in
    if size <> 0l then
      let payload = read_all ~count:(Int32.to_int size) socket in
      (msg_type, payload)
    else (msg_type, "")
  with
  | End_of_file -> raise Connection_closed
  | exn ->
      close socket;
      raise exn

let rec read_next_raw_message ~magic_string socket f =
  let raw = read_raw_message ~magic_string socket in
  if f raw then raw else read_next_raw_message ~magic_string socket f

let accept server =
  let socket, _ = Unix.accept server in
  socket

let create_server path =
  let socket = Unix.socket PF_UNIX SOCK_STREAM 0 in
  let socket_exists = Sys.file_exists path in
  if socket_exists then Unix.unlink path;
  let sockaddr = Unix.ADDR_UNIX path in
  Unix.bind socket sockaddr;
  Unix.listen socket 100;
  socket
