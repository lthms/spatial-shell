(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

val socket_path : unit -> string

type target = Left | Right | Up | Down | Workspace of int
type layout = Maximize | Column
type operation = Incr | Decr

type command =
  | Default_layout of int option * layout
  | Default_column_count of int option * int
  | Window of int
  | Focus of target
  | Move of target
  | Layout of layout
  | Toggle_layout
  | Column_count of operation
  | Set_status_bar_name of string

val command_of_string : string -> command option

val command_of_string_exn : string -> command
(** @raise [Invalid_argument] *)

type run_command_reply = { success : bool }
type window = { app_id : string; name : string }
type get_windows_reply = { focus : int option; windows : window list }
type get_workspaces_reply = { focus : int; windows : (int * window) list }
type get_workspace_config_reply = { layout : layout; column_count : int }

val run_command_reply_encoding : run_command_reply Jsoner.t
val get_windows_reply_encoding : get_windows_reply Jsoner.t
val get_workspaces_reply_encoding : get_workspaces_reply Jsoner.t
val get_workspace_config_reply_encoding : get_workspace_config_reply Jsoner.t

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
