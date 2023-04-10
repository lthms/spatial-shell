(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Mltp_ipc

let socket_path = "/tmp/spatial-sway.socket"
let magic_string = "spatial-ipc"

type target = Prev | Next | Index of int

let target_of_string_opt = function
  | "prev" -> Some Prev
  | "next" -> Some Next
  | x ->
      Option.bind (int_of_string_opt x) @@ fun x ->
      if 0 <= x then Some (Index x) else None

let target_to_string = function
  | Prev -> "prev"
  | Next -> "next"
  | Index x -> string_of_int x

type move_target = Left | Right | Up | Down

let move_target_of_string_opt = function
  | "left" -> Some Left
  | "right" -> Some Right
  | "up" -> Some Up
  | "down" -> Some Down
  | _ -> None

let move_target_to_string = function
  | Left -> "left"
  | Right -> "right"
  | Up -> "up"
  | Down -> "down"

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

type 'a builtin = Visible_windows : int builtin | Focus_view : bool builtin
type 'a scoped = { workspace : int option; builtin : 'a builtin }

type command =
  | Default : 'a scoped * 'a -> command
  | Focus of target
  | Workspace of target
  | Move of move_target
  | Maximize of switch
  | Split of operation

let ( <$> ) = Option.map

let ( <*> ) f x =
  match (f, x) with Some f, Some x -> Some (f x) | _, _ -> None

let command_of_string str =
  String.split_on_char ' ' str
  |> List.filter (function "" -> false | _ -> true)
  |> function
  | [ "default"; "focus"; x ] ->
      (fun x -> Default ({ workspace = None; builtin = Focus_view }, x))
      <$> bool_of_string_opt x
  | [ "workspace"; ws; "default"; "focus"; x ] ->
      (fun x ws -> Default ({ workspace = Some ws; builtin = Focus_view }, x))
      <$> bool_of_string_opt x <*> int_of_string_opt ws
  | [ "default"; "columns"; x ] ->
      (fun x -> Default ({ workspace = None; builtin = Visible_windows }, x))
      <$> int_of_string_opt x
  | [ "workspace"; ws; "default"; "columns"; x ] ->
      (fun x ws ->
        Default ({ workspace = Some ws; builtin = Visible_windows }, x))
      <$> int_of_string_opt x <*> int_of_string_opt ws
  | [ "focus"; target ] -> (fun x -> Focus x) <$> target_of_string_opt target
  | [ "workspace"; target ] ->
      (fun x -> Workspace x) <$> target_of_string_opt target
  | [ "move"; target ] -> (fun x -> Move x) <$> move_target_of_string_opt target
  | [ "maximize"; switch ] ->
      (fun x -> Maximize x) <$> switch_of_string_opt switch
  | [ "split"; op ] -> (fun x -> Split x) <$> operation_of_string_opt op
  | _ -> None

let command_of_string_exn str =
  match command_of_string str with
  | Some x -> x
  | None -> raise (Invalid_argument "Spatial_ipc.command_of_string_exn")

let command_to_string = function
  | Default ({ workspace; builtin = Focus_view }, x) ->
      Format.(
        asprintf "%adefault focus %a"
          (pp_print_option (fun fmt x -> fprintf fmt "workspace %d " x))
          workspace pp_print_bool x)
  | Default ({ workspace; builtin = Visible_windows }, x) ->
      Format.(
        asprintf "%adefault columns %d"
          (pp_print_option (fun fmt x -> fprintf fmt "workspace %d " x))
          workspace x)
  | Focus dir -> Format.sprintf "focus %s" (target_to_string dir)
  | Workspace dir -> Format.sprintf "workspace %s" (target_to_string dir)
  | Move dir -> Format.sprintf "move %s" (move_target_to_string dir)
  | Maximize switch -> Format.sprintf "maximize %s" (switch_to_string switch)
  | Split op -> Format.sprintf "split %s" (operation_to_string op)

type run_command_reply = { success : bool }

let run_command_reply_encoding =
  let open Data_encoding in
  conv
    (fun { success } -> success)
    (fun success -> { success })
    (obj1 (req "success" bool))

type window_info = { workspace : string; app_id : string; name : string }
type get_windows_reply = { focus : int option; windows : window_info list }

let window_info_encoding : window_info Data_encoding.t =
  let open Data_encoding in
  conv
    (fun { workspace; app_id; name } -> (workspace, app_id, name))
    (fun (workspace, app_id, name) -> { workspace; app_id; name })
    (obj3 (req "focus" string) (req "app_id" string) (req "name" string))

let get_windows_reply_encoding : get_windows_reply Data_encoding.t =
  let open Data_encoding in
  conv
    (fun { focus; windows } -> (focus, windows))
    (fun (focus, windows) -> { focus; windows })
    (obj2 (opt "focus" int31) (req "windows" @@ list window_info_encoding))

type get_workspaces_reply = {
  current : int;
  windows : (int * window_info) list;
}

let get_workspaces_reply_encoding : get_workspaces_reply Data_encoding.t =
  let open Data_encoding in
  conv
    (fun { current; windows } -> (current, windows))
    (fun (current, windows) -> { current; windows })
    (obj2 (req "current" int31)
       (req "windows" @@ list (tup2 int31 window_info_encoding)))

type 'a t =
  | Run_command : command -> run_command_reply t
  | Get_windows : get_windows_reply t
  | Get_workspaces : get_workspaces_reply t

let reply_encoding : type a. a t -> a Data_encoding.t = function
  | Run_command _ -> run_command_reply_encoding
  | Get_windows -> get_windows_reply_encoding
  | Get_workspaces -> get_workspaces_reply_encoding

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
  | None ->
      Format.printf "%S\n" reply;
      failwith "cannot parse reply"

let to_raw_message : type a. a t -> Raw_message.t = function
  | Run_command cmd -> (0l, command_to_string cmd)
  | Get_windows -> (1l, "")
  | Get_workspaces -> (2l, "")

type packed = Packed : 'a t -> packed

let of_raw_message (op, payload) =
  match op with
  | 0l -> (fun x -> Packed (Run_command x)) <$> command_of_string payload
  | 1l -> Some (Packed Get_windows)
  | 2l -> Some (Packed Get_workspaces)
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
