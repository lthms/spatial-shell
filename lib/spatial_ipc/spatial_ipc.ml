(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Mltp_ipc

let socket_path () =
  let ( // ) = Filename.concat in
  let base =
    match Sys.getenv_opt "XDG_RUNTIME_DIR" with
    | Some base -> base
    | None -> "/tmp"
  in
  base // "spatial.sock"

let magic_string = "spatial-ipc"

let pos_int =
  let open Miam in
  let+ ws = int in
  assert (0 <= ws);
  ws

let index_parser = pos_int
let workspace_parser = pos_int

type target = Prev | Next | Index of int

let target_parser =
  let open Miam in
  string "prev" *> return Prev
  <|> string "next" *> return Next
  <|> let+ x = index_parser in
      Index x

let target_to_string = function
  | Prev -> "prev"
  | Next -> "next"
  | Index x -> string_of_int x

type move_target = Left | Right | Up | Down

let move_target_parser =
  let open Miam in
  enum [ ("left", Left); ("right", Right); ("up", Up); ("down", Down) ]

let move_target_to_string = function
  | Left -> "left"
  | Right -> "right"
  | Up -> "up"
  | Down -> "down"

type switch = On | Off | Toggle

let switch_parser =
  let open Miam in
  enum [ ("on", On); ("off", Off); ("toggle", Toggle) ]

let switch_to_string = function On -> "on" | Off -> "off" | Toggle -> "toggle"

type operation = Incr | Decr

let operation_parser =
  let open Miam in
  enum [ ("increment", Incr); ("decrement", Decr) ]

let operation_to_string = function Incr -> "increment" | Decr -> "decrement"

let workspace_scope_parser =
  let open Miam in
  (let+ x =
     whitespaces *> string "[workspace=" *> workspace_parser
     <* string "]" <* whitespaces
   in
   Some x)
  <|> return None

type command =
  | Set_focus_default of int option * bool
  | Set_visible_windows_default of int option * int
  | Background of string
  | Window of target
  | Workspace of target
  | Move of move_target
  | Maximize of switch
  | Split of operation

let bool_parser =
  let open Miam in
  enum [ ("true", true); ("false", false) ]

let command_parser =
  let open Miam in
  (let+ ws = workspace_scope_parser
   and+ b = word "default" *> word "focus" *> bool_parser in
   Set_focus_default (ws, b))
  <|> (let+ ws = workspace_scope_parser
       and+ i = word "default" *> word "visible" *> word "windows" *> int in
       assert (1 < i);
       Set_visible_windows_default (ws, i))
  <|> (let+ path = word "background" *> quoted in
       Background path)
  <|> (let+ target = word "window" *> target_parser in
       Window target)
  <|> (let+ target = word "workspace" *> target_parser in
       Workspace target)
  <|> (let+ target = word "move" *> move_target_parser in
       Move target)
  <|> (let+ switch = word "maximize" *> switch_parser in
       Maximize switch)
  <|> (let+ op = word "split" *> operation_parser in
       Split op)
  <* whitespaces

let command_of_string = Miam.(run (command_parser <* empty))

let command_of_string_exn str =
  match command_of_string str with
  | Some x -> x
  | None -> raise (Invalid_argument "Spatial_ipc.command_of_string_exn")

let command_to_string = function
  | Set_focus_default (workspace, x) ->
      Format.(
        asprintf "%adefault focus %a"
          (pp_print_option
             ~none:(fun fmt () -> fprintf fmt "[workspace=*]")
             (fun fmt x -> fprintf fmt "[workspace=%d] " x))
          workspace pp_print_bool x)
  | Set_visible_windows_default (workspace, x) ->
      Format.(
        asprintf "%adefault columns %d"
          (pp_print_option
             ~none:(fun fmt () -> fprintf fmt "[workspace=*]")
             (fun fmt x -> fprintf fmt "[workspace=%d] " x))
          workspace x)
  | Background path -> Format.sprintf "background \"%s\"" path
  | Window dir -> Format.sprintf "window %s" (target_to_string dir)
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

type get_workspace_config_reply = {
  maximized : bool;
  maximum_visible_windows : int;
}

let get_workspace_config_reply_encoding :
    get_workspace_config_reply Data_encoding.t =
  let open Data_encoding in
  conv
    (fun { maximized; maximum_visible_windows } ->
      (maximized, maximum_visible_windows))
    (fun (maximized, maximum_visible_windows) ->
      { maximized; maximum_visible_windows })
    (obj2 (req "maximized" bool) (req "maximum_visible_windows" int31))

type 'a t =
  | Run_command : command -> run_command_reply t
  | Get_windows : get_windows_reply t
  | Get_workspaces : get_workspaces_reply t
  | Get_workspace_config : get_workspace_config_reply t

let reply_encoding : type a. a t -> a Data_encoding.t = function
  | Run_command _ -> run_command_reply_encoding
  | Get_windows -> get_windows_reply_encoding
  | Get_workspaces -> get_workspaces_reply_encoding
  | Get_workspace_config -> get_workspace_config_reply_encoding

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
  | Get_workspace_config -> (3l, "")

type packed = Packed : 'a t -> packed

let ( <$> ) = Option.map

let of_raw_message (op, payload) =
  match op with
  | 0l -> (fun x -> Packed (Run_command x)) <$> command_of_string payload
  | 1l -> Some (Packed Get_windows)
  | 2l -> Some (Packed Get_workspaces)
  | 3l -> Some (Packed Get_workspace_config)
  | _ -> None

type socket = Socket.socket

let connect () : socket = Socket.connect (socket_path ())
let close socket = Socket.close socket

let with_socket ?socket f =
  match socket with
  | Some socket -> f socket
  | None -> Socket.with_socket (socket_path ()) f

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

let create_server () = Socket.create_server (socket_path ())
let accept = Socket.accept

let from_file path =
  try
    let ic = open_in path in

    let rec read acc =
      try
        let line = input_line ic in
        read (command_of_string_exn line :: acc)
      with End_of_file -> List.rev acc
    in
    Some (read [])
  with _ -> None
