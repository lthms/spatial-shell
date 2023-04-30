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

let workspace_parser = pos_int

type target = Left | Right | Up | Down

let target_parser =
  let open Miam in
  enum [ ("left", Left); ("right", Right); ("up", Up); ("down", Down) ]

let target_to_string = function
  | Left -> "left"
  | Right -> "right"
  | Up -> "up"
  | Down -> "down"

type layout = Maximize | Column

let layout_parser =
  let open Miam in
  enum [ ("maximize", Maximize); ("column", Column) ]

let layout_to_string = function Maximize -> "maximize" | Column -> "column"

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
  | Default_layout of int option * layout
  | Default_column_count of int option * int
  | Set_unfocus_opacity of int
  | Background of string
  | Window of int
  | Focus of target
  | Move of target
  | Layout of layout
  | Toggle_layout
  | Column_count of operation

let command_parser =
  let open Miam in
  (let+ ws = workspace_scope_parser
   and+ b = word "default" *> word "layout" *> layout_parser in
   Default_layout (ws, b))
  <|> (let+ ws = workspace_scope_parser
       and+ i = word "default" *> word "column" *> word "count" *> int in
       assert (1 < i);
       Default_column_count (ws, i))
  <|> (let+ p = word "unfocus" *> word "opacity" *> int in
       assert (0 <= p && p <= 100);
       Set_unfocus_opacity p)
  <|> (let+ path = word "background" *> quoted in
       Background path)
  <|> (let+ target = word "window" *> int in
       Window target)
  <|> (let+ target = word "focus" *> target_parser in
       Focus target)
  <|> (let+ target = word "move" *> target_parser in
       Move target)
  <|> (let+ layout = word "layout" *> layout_parser in
       Layout layout)
  <|> word "toggle" *> word "layout" *> return Toggle_layout
  <|> (let+ op = word "column" *> word "count" *> operation_parser in
       Column_count op)
  <* whitespaces

let command_of_string = Miam.(run (command_parser <* empty))

let command_of_string_exn str =
  match command_of_string str with
  | Some x -> x
  | None -> raise (Invalid_argument "Spatial_ipc.command_of_string_exn")

let command_to_string = function
  | Default_layout (workspace, x) ->
      Format.(
        asprintf "%adefault layout %a"
          (pp_print_option (fun fmt x -> fprintf fmt "[workspace=%d] " x))
          workspace pp_print_string (layout_to_string x))
  | Default_column_count (workspace, x) ->
      Format.(
        asprintf "%adefault column count %d"
          (pp_print_option (fun fmt x -> fprintf fmt "[workspace=%d] " x))
          workspace x)
  | Set_unfocus_opacity p -> Format.sprintf "unfocus opacity %d" p
  | Background path -> Format.sprintf "background \"%s\"" path
  | Window dir -> Format.sprintf "window %s" (string_of_int dir)
  | Focus dir -> Format.sprintf "focus %s" (target_to_string dir)
  | Move dir -> Format.sprintf "move %s" (target_to_string dir)
  | Layout layout -> Format.sprintf "layout %s" (layout_to_string layout)
  | Toggle_layout -> "toggle layout"
  | Column_count op -> Format.sprintf "column count %s" (operation_to_string op)

type run_command_reply = { success : bool }

let run_command_reply_encoding =
  let open Jsoner in
  conv
    (fun { success } -> success)
    (fun success -> { success })
    (obj1 (req "success" bool))

type window = { app_id : string; name : string }
type get_windows_reply = { focus : int option; windows : window list }

let window_encoding : window Jsoner.t =
  let open Jsoner in
  conv
    (fun { app_id; name } -> (app_id, name))
    (fun (app_id, name) -> { app_id; name })
    (obj2 (req "app_id" string) (req "name" string))

let get_windows_reply_encoding : get_windows_reply Jsoner.t =
  let open Jsoner in
  conv
    (fun { focus; windows } -> (focus, windows))
    (fun (focus, windows) -> { focus; windows })
    (obj2 (opt "focus" int) (req "windows" @@ list window_encoding))

type get_workspaces_reply = { focus : int; windows : (int * window) list }

let get_workspaces_reply_encoding : get_workspaces_reply Jsoner.t =
  let open Jsoner in
  conv
    (fun { focus; windows } -> (focus, windows))
    (fun (focus, windows) -> { focus; windows })
    (obj2 (req "focus" int)
       (req "workspaces"
       @@ list (obj2 (req "index" int) (req "focused_window" window_encoding))))

type get_workspace_config_reply = { layout : layout; column_count : int }

let layout_encoding =
  Jsoner.string_enum [ ("maximize", Maximize); ("column", Column) ]

let get_workspace_config_reply_encoding : get_workspace_config_reply Jsoner.t =
  let open Jsoner in
  conv
    (fun { layout; column_count } -> (layout, column_count))
    (fun (layout, column_count) -> { layout; column_count })
    (obj2 (req "layout" layout_encoding) (req "column_count" int))

type 'a t =
  | Run_command : command -> run_command_reply t
  | Get_windows : get_windows_reply t
  | Get_workspaces : get_workspaces_reply t
  | Get_workspace_config : get_workspace_config_reply t

let reply_encoding : type a. a t -> a Jsoner.t = function
  | Run_command _ -> run_command_reply_encoding
  | Get_windows -> get_windows_reply_encoding
  | Get_workspaces -> get_workspaces_reply_encoding
  | Get_workspace_config -> get_workspace_config_reply_encoding

let reply_to_string : type a. a t -> a -> string =
 fun cmd reply -> Jsoner.to_string_exn ~minify:true (reply_encoding cmd) reply

let reply_of_string : type a. a t -> string -> a option =
 fun cmd reply ->
  let open Jsoner in
  from_string (reply_encoding cmd) reply

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
