(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

val socket_path : unit -> string

type target = Left | Right | Up | Down
type switch = On | Off | Toggle
type operation = Incr | Decr

type command =
  | Set_focus_default of int option * bool
  | Set_visible_windows_default of int option * int
  | Background of string
  | Window of int
  | Focus of target
  | Move of target
  | Maximize of switch
  | Split of operation

val command_of_string : string -> command option

val command_of_string_exn : string -> command
(** @raise [Invalid_argument] *)

type run_command_reply = { success : bool }
type window_info = { workspace : string; app_id : string; name : string }
type get_windows_reply = { focus : int option; windows : window_info list }

type get_workspaces_reply = {
  current : int;
  windows : (int * window_info) list;
}

type get_workspace_config_reply = {
  maximized : bool;
  maximum_visible_windows : int;
}

type 'a t =
  | Run_command : command -> run_command_reply t
  | Get_windows : get_windows_reply t
  | Get_workspaces : get_workspaces_reply t
  | Get_workspace_config : get_workspace_config_reply t

type socket = Unix.file_descr

val connect : unit -> socket
val close : socket -> unit
val with_socket : ?socket:socket -> (socket -> 'a) -> 'a
val send_command : ?socket:socket -> 'a t -> 'a

type ('a, 'b) handler = { handler : 'r. 'a -> 'r t -> 'b * 'r }

val handle_next_command : socket:socket -> 'u -> ('u, 'v) handler -> 'v option
val create_server : unit -> socket
val accept : socket -> socket
val from_file : string -> command list option
