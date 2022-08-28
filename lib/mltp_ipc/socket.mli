(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

(** We call MTLP protocol a protocol consisting in sending and
    receiving messages serialized as follows:

    {ul {li A {b M}agic string}
        {li A 32-bit integer representing the {b T}ype of the payload}
        {li A 32-bit integer representing the {b L}ength of the payload}
        {li The {b P}ayload itself}} *)

type socket = Unix.file_descr
(** A socket to communicate with a peer using the so-called MTLP protocol. *)

val connect : string -> socket
(** Establish a bi-directional connection with a peer. *)

val close : socket -> unit
(** Close a bi-directional connection with a peer. *)

val with_socket : string -> (socket -> 'a) -> 'a
(** [with_socket path k] establishes a bi-connection with a peer using
    the UNIX socket located at [path], hands over the socket to the
    continuation [k], and takes care of closing the connection prior
    to returning the result, even in case of an exception. *)

exception Bad_magic_string of string
(** When trying to read a MTLP message, the magic string was not
    correct. *)

exception Connection_closed
(** When trying to receive from or send a message to a closed
    bi-directional connection. *)

val read_raw_message : magic_string:string -> socket -> Raw_message.t
(** [read_raw_message ~magic_string socket] reads a MTLP
    message from [socket].

    @raise Bad_magic_string (closes [socket] when it happens)
    @raise Connection_closed *)

val read_next_raw_message :
  magic_string:string -> socket -> (Raw_message.t -> bool) -> Raw_message.t
(** [read_next_raw_message ~magic_string socket f] returns the next
    raw message received by [socket] which satisfies [f]’s
    conditions. Messages that don’t satisfy [f]’s conditions are
    ignored.

    @raise Bad_magic_string (closes [socket] when it happens)
    @raise Connection_closed *)

val write_raw_message : magic_string:string -> socket -> Raw_message.t -> unit
(** @raise Connection_closed *)

val create_server : string -> socket
val accept : socket -> socket
