(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Mltp_ipc

let socket_path = "/tmp/spatial-sway.socket"
let magic_string = "spatial-ipc"

type focus = Focus_kind
type move = Move_kind

type 'kind target =
  | Prev : 'kind target
  | Next : 'kind target
  | Index : int -> focus target

let restrict_move_target : 'k target -> move target option = function
  | Index _ -> None
  | Next -> Some Next
  | Prev -> Some Prev

let target_of_string_opt = function
  | "prev" -> Some Prev
  | "next" -> Some Next
  | x ->
      Option.bind (int_of_string_opt x) @@ fun x ->
      if 0 <= x then Some (Index x) else None

let target_to_string : type kind. kind target -> string = function
  | Prev -> "prev"
  | Next -> "next"
  | Index x -> string_of_int x

type switch = On | Off | Toggle

let switch_of_string_opt = function
  | "on" -> Some On
  | "off" -> Some Off
  | "toggle" -> Some Toggle
  | _ -> None

let switch_to_string = function On -> "on" | Off -> "off" | Toggle -> "toggle"

type operation = Incr | Decr

let operation_of_string_opt = function
  | "increment" -> Some Incr
  | "decrement" -> Some Decr
  | _ -> None

let operation_to_string = function Incr -> "increment" | Decr -> "decrement"

type command =
  | Focus of focus target
  | Move of move target
  | Maximize of switch
  | Split of operation

let ( <$> ) = Option.map

let command_of_string str =
  String.split_on_char ' ' str
  |> List.filter (function "" -> false | _ -> true)
  |> function
  | [ "focus"; target ] -> (fun x -> Focus x) <$> target_of_string_opt target
  | [ "move"; target ] ->
      Option.bind (target_of_string_opt target) @@ fun target ->
      (fun x -> Move x) <$> restrict_move_target target
  | [ "maximize"; switch ] ->
      (fun x -> Maximize x) <$> switch_of_string_opt switch
  | [ "split"; op ] -> (fun x -> Split x) <$> operation_of_string_opt op
  | _ -> None

let command_of_string_exn str =
  match command_of_string str with
  | Some x -> x
  | None -> raise (Invalid_argument "Spatial_ipc.command_of_string_exn")

let command_to_string = function
  | Focus dir -> Format.sprintf "focus %s" (target_to_string dir)
  | Move dir -> Format.sprintf "move %s" (target_to_string dir)
  | Maximize switch -> Format.sprintf "maximize %s" (switch_to_string switch)
  | Split op -> Format.sprintf "split %s" (operation_to_string op)

type run_command_reply = { success : bool }

let run_command_reply_encoding =
  let open Data_encoding in
  conv
    (fun { success } -> success)
    (fun success -> { success })
    (obj1 (req "success" bool))

type get_windows_reply = { focus : int option; windows : string list }

let get_windows_reply_encoding : get_windows_reply Data_encoding.t =
  let open Data_encoding in
  conv
    (fun { focus; windows } -> (focus, windows))
    (fun (focus, windows) -> { focus; windows })
    (obj2 (opt "focus" int31) (req "windows" @@ list string))

type 'a t =
  | Run_command : command -> run_command_reply t
  | Get_windows : get_windows_reply t

let reply_encoding : type a. a t -> a Data_encoding.t = function
  | Run_command _ -> run_command_reply_encoding
  | Get_windows -> get_windows_reply_encoding

let reply_to_string : type a. a t -> a -> string =
 fun cmd reply ->
  Data_encoding.Json.(to_string (construct (reply_encoding cmd) reply))

let reply_of_string : type a. a t -> string -> a option =
 fun cmd reply ->
  let open Data_encoding.Json in
  try
    match from_string reply with
    | Ok json -> Some (destruct (reply_encoding cmd) json)
    | _ -> None
  with _ -> None

let reply_of_string_exn cmd reply =
  match reply_of_string cmd reply with
  | Some x -> x
  | None -> failwith "cannot parse reply"

let to_raw_message : type a. a t -> Raw_message.t = function
  | Run_command cmd -> (0l, command_to_string cmd)
  | Get_windows -> (1l, "")

type packed = Packed : 'a t -> packed

let of_raw_message (op, payload) =
  match op with
  | 0l -> (fun x -> Packed (Run_command x)) <$> command_of_string payload
  | 1l -> Some (Packed Get_windows)
  | _ -> None

type socket = Socket.socket

let connect () : socket = Socket.connect socket_path
let close socket = Socket.close socket

let with_socket ?socket f =
  match socket with
  | Some socket -> f socket
  | None -> Socket.with_socket socket_path f

let send_command ?socket cmd =
  with_socket ?socket @@ fun socket ->
  let ((op, _) as raw) = to_raw_message cmd in
  Socket.write_raw_message ~magic_string socket raw;
  let op', payload = Socket.read_raw_message ~magic_string socket in
  assert (op = op');
  reply_of_string_exn cmd payload

type ('a, 'b) handler = { handler : 'r. 'a -> 'r t -> 'b * 'r }

let handle_next_command ~socket input { handler } =
  let ((op, _) as raw) = Socket.read_raw_message ~magic_string socket in
  let cmd = of_raw_message raw in
  match cmd with
  | Some (Packed cmd) ->
      let output, reply = handler input cmd in
      Socket.write_raw_message ~magic_string socket
        (op, reply_to_string cmd reply);
      Some output
  | None ->
      Socket.write_raw_message ~magic_string socket (op, "");
      None

let create_server () = Socket.create_server socket_path
let accept = Socket.accept
