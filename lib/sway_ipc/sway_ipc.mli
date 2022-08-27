(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type socket
(** A socket to interact with Sway. *)

exception Sway_ipc_error of Mltp_ipc.Socket.error

val connect : unit -> socket Lwt.t
(** [connect ()] establishes a connection with Sway. This connection
    can be ended by using {!close}.

    When possible, it is advised to use {!with_socket}. *)

val close : socket -> unit Lwt.t
(** [close socket] puts an end to a connection with Sway. *)

val with_socket : (socket -> 'a Lwt.t) -> 'a Lwt.t
(** [with_socket k] establishes a bi-connection with Sway, hands over
    the socket to the continuation [k], and takes care of closing the
    connection prior to returning the result, even in case of an
    exception. *)

val send_command : ?socket:socket -> 'a Sway_ipc_types.Message.t -> 'a Lwt.t
(** [send_command ?socket msg] sends the command [msg] to Sway (by
    establishing (either by using [socket], or by establishing a fresh
    connection if [socket] is omitted), and returns the result sent
    back by Sway.

    This is a low-level helpers. It is advised to use specialized
    helpers whenever they are available. *)

val subscribe :
  ?socket:socket ->
  Sway_ipc_types.Event.event_type list ->
  Sway_ipc_types.Event.t Lwt_stream.t Lwt.t
(** [subscribe ?socket evs] returns a stream of events sent by Sway,
    matching the event types listed in [evs].

    The socket passed as argument should not be used to send commands
    afterwards. *)

val get_tree : ?socket:socket -> unit -> Sway_ipc_types.Node.t Lwt.t
(** [get_tree ?socket ()] returns the current state of the tree
    manipulated by Sway.

    If [socket] is omitted, a fresh connection is established with
    Sway. *)

val get_current_workspace :
  ?socket:socket -> unit -> Sway_ipc_types.Workspace.t Lwt.t
(** [get_current_workspace ?socket ()] returns the workspace currently
    focused by Sway.

    If [socket] is omitted, a fresh connection is established with
    Sway. *)
