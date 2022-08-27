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

val read_raw_message : magic_string:string -> socket -> Raw_message.t Lwt.t

val read_next_raw_message :
  magic_string:string ->
  socket ->
  (Raw_message.t -> bool) ->
  Raw_message.t Lwt.t
(** [read_next_raw_message ~magic_string socket f] returns the next
    raw message received by [socket] which satisfies [f]’s
    conditions. Messages that don’t satisfy [f]’s conditions are
    ignored. *)

val write_raw_message :
  magic_string:string -> socket -> Raw_message.t -> unit Lwt.t
