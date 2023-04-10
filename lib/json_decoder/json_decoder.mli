(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type 'a t
(** A Json decoder for a value of type ['a].

    Note that it is possible to provide a Json value that is a
    superset of what a decoder requires. *)

val of_string : 'a t -> string -> 'a option
(** [of_string enc input] interprets [input] as a serialized Json
    value, then uses [enc] to decode it into an OCaml value, if
    possible. It returns [None] in case of error. *)

val of_string_exn : 'a t -> string -> 'a
(** Same as [of_string], but raises exceptions in case of error. *)

(** This modules provides a monadic interface to compose existing
    decoders together. *)
module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  (** The [bind] operator. *)

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
  (** The [map] operator. *)

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t

  val return : 'a -> 'a t
  (** [return x] is the decoder that ignores the input Json value, and
      always return [x]. *)
end

val field : string -> 'a t -> 'a t
(** [field name dec] decodes the input Json as an object which
    contains at least one property whose name is [name], and whose
    value can be decoded with [dec]. The resulting OCaml value is
    returned as-is.

    [field] is typically used to read from several property of an
    object, which can later be composed together.

    {[
      let tup2 dl dr =
        let open Json_decoder.Syntax in
        let+ x = field "0" dl
        and+ y = field "1" dr in
        (x, y)
    ]}

    The decoding will fail in the input Json value does not have a
    property [name]. *)

val field_opt : string -> 'a t -> 'a option t
(** Same as {!field}, but the the decoding will not fail if the input
    Json value does not have the expected property. In that case,
    [None] is returned. *)

val list : 'a t -> 'a list t
(** [list enc] decodes the input Json value as a list of values which
    can be decoded using [enc].  *)

val string : string t
(** [string] decodes the input Json value as a string. *)

val int64 : int64 t
(** [int64] decodes the input Json value as an 64-byte integer. *)

val bool : bool t
(** [bool] decodes the input Json value as a boolean. *)

val float : float t
(** [float] decodes the input Json value as a float. *)

val string_enum : (string * 'a) list -> 'a t
(** [string_enum l] decodes the input Json value as a string, then
    compare said string with the values contained in the associated
    list [l], to return the OCaml value associated to that string. *)

val mu : ('a t -> 'a t) -> 'a t
(** [mu] is a combinator that lets you write a recursive decoder,
    without having to write a recursive function. For instance, if you
    manipulate an object containing a list of similar objects
    (typically, a tree), then you can use [mu] to express that.

    {[
      type tree = { value : int64; children : tree list }

      let decoder =
        let open Json_decoder in
        let open Syntax in
        mu (fun tree_decoder ->
            let+ value = field "value" int64
            and+ children = field "children" @@ list tree_decoder in
            { value; children })
    ]}

    Here [decoder] will behave as expected.

    {v
      # Json_decoder.of_string decoder "{ \"value\": 3 , \"children\" : [] }" ;;
      - : tree option = Some {value = 3L; children = []}
      # Json_decoder.of_string decoder "{ \"value\": 3 , \"children\" : [ { \"value\": 5, \"children\": [] } ] }" ;;
      - : tree option = Some {value = 3L; children = [{value = 5L; children = []}]}
    v}*)
