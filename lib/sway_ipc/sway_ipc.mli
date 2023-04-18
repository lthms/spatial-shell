(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type socket = Unix.file_descr
(** A socket to interact with Sway. *)

val connect : unit -> socket
(** [connect ()] establishes a connection with Sway. This connection
    can be ended by using {!close}.

    When possible, it is advised to use {!with_socket}. *)

val close : socket -> unit
(** [close socket] puts an end to a connection with Sway. *)

val with_socket : ?socket:socket -> (socket -> 'a) -> 'a
(** [with_socket ?socket k] establishes a bi-connection with Sway,
    hands over the socket to the continuation [k], and takes care of
    closing the connection prior to returning the result, even in case
    of an exception. *)

val send_command : ?socket:socket -> 'a Sway_ipc_types.Message.t -> 'a
(** [send_command ?socket msg] sends the command [msg] to Sway (by
    establishing (either by using [socket], or by establishing a fresh
    connection if [socket] is omitted), and returns the result sent
    back by Sway.

    This is a low-level helpers. It is advised to use specialized
    helpers whenever they are available. *)

val read_event : socket -> Sway_ipc_types.Event.t

val subscribe : Sway_ipc_types.Event.event_type list -> socket
(** [subscribe ?socket evs] returns a stream of events sent by Sway,
    matching the event types listed in [evs].

    The socket passed as argument should not be used to send commands
    afterwards. *)

val get_tree : ?socket:socket -> unit -> Sway_ipc_types.Node.t
(** [get_tree ?socket ()] returns the current state of the tree
    manipulated by Sway.

    If [socket] is omitted, a fresh connection is established with
    Sway. *)

val get_current_workspace : ?socket:socket -> unit -> Sway_ipc_types.Workspace.t
(** [get_current_workspace ?socket ()] returns the workspace currently
    focused by Sway.

    If [socket] is omitted, a fresh connection is established with
    Sway. *)

val send_tick :
  ?socket:socket -> string -> Sway_ipc_types.Message.send_tick_reply
(** [send_tick ?socket payload] sends a tick with a given [payload] to Sway. As
    a result, every subscriber of the Tick event will received said payload. *)
