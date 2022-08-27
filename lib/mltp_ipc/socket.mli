(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

(** We call MTLP protocol a protocol consisting in sending and
    receiving messages serialized as follows:

    {ul {li A {b M}agic string}
        {li A 32-bit integer representing the {b T}ype of the payload}
        {li A 32-bit integer representing the {b L}ength of the payload}
        {li The {b P}ayload itself}} *)

type socket
(** A socket to communicate with a peer using the so-called MTLP protocol. *)

val connect : string -> socket Lwt.t
(** Establish a bi-directional connection with a peer. *)

val close : socket -> unit Lwt.t
(** Close a bi-directional connection with a peer. *)

type error =
  | Bad_magic_string of string
      (** When trying to read a MTLP message, the magic string was not
          correct. *)
  | Connection_closed
      (** When trying to receive from or send a message to a closed
          bi-directional connection. *)

val read_raw_message :
  magic_string:string -> socket -> (Raw_message.t, error) result Lwt.t
(** [read_raw_message ~magic_string socket] reads a MTLP
    message from [socket].

    This function may fail with the following errors:

    {ul {li [Bad_magic_string] (closes [socket] when it happens)}
        {li [Connection_closed]}} *)

val read_next_raw_message :
  magic_string:string ->
  socket ->
  (Raw_message.t -> bool) ->
  (Raw_message.t, error) result Lwt.t
(** [read_next_raw_message ~magic_string socket f] returns the next
    raw message received by [socket] which satisfies [f]’s
    conditions. Messages that don’t satisfy [f]’s conditions are
    ignored.

    This function may fail with the following errors:

    {ul {li [Bad_magic_string] (closes [socket] when it happens)}
        {li [Connection_closed]}} *)

val write_raw_message :
  magic_string:string -> socket -> Raw_message.t -> (unit, error) result Lwt.t
(** This function may fail with [Connection_closed]. *)
