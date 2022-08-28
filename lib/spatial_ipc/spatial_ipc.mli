(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

val socket_path : string

type direction = Left | Right
type switch = On | Off | Toggle
type operation = Incr | Decr

type command =
  | Focus of direction
  | Move of direction
  | Maximize of switch
  | Split of operation

val command_of_string : string -> command option

val command_of_string_exn : string -> command
(** @raise [Invalid_argument] *)

type run_command_reply = { success : bool }
type get_windows_reply = { focus : int option; windows : string list }

type 'a t =
  | Run_command : command -> run_command_reply t
  | Get_windows : get_windows_reply t

type socket = Unix.file_descr

val connect : unit -> socket
val close : socket -> unit
val with_socket : ?socket:socket -> (socket -> 'a) -> 'a
val send_command : ?socket:socket -> 'a t -> 'a

type ('a, 'b) handler = { handler : 'r. 'a -> 'r t -> 'b * 'r }

val handle_next_command : socket:socket -> 'u -> ('u, 'v) handler -> 'v option
val create_server : unit -> socket
val accept : socket -> socket
