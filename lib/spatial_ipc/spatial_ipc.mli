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

type 'a t = Run_command : command -> unit t
type socket

val connect : unit -> socket Lwt.t
val close : socket -> unit Lwt.t
val with_socket : (socket -> 'a Lwt.t) -> 'a Lwt.t
val send_command : ?socket:socket -> 'a t -> 'a Lwt.t

type ('a, 'b) handler = { handler : 'r. 'a -> 'r t -> ('b option * 'r) Lwt.t }

val handle_next_command :
  socket:socket -> 'u -> ('u, 'v) handler -> 'v option Lwt.t

val create_server : unit -> socket Lwt_stream.t Lwt.t
