(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

(** JSON encoding/decoding library a la data-encoding, but without the
    dependency to [ZArith], and accepting JSON values which are supersets of the
    expected object. *)

type 'a t
(** A JSON encoder/decoder, nicknamed Jsoner in the context of this library,
    for a value o type ['a]. *)

val to_string_exn : minify:bool -> 'a t -> 'a -> string
(** [to_string_exn ~minify jsoner value] encodes [value] using [jsoner] into a
    JSON value serialized in a string. Will raise an exception in case [jsoner]
    cannot serialize [value]. *)

val to_string : minify:bool -> 'a t -> 'a -> string option
(** [to_string ~minify jsoner value] encodes [value] using [jsoner] into a JSON
    value serialized in a string. Will return [None] in case [jsoner] cannot
    serialize [value]. *)

val from_string_exn : 'a t -> string -> 'a
(** [from_string_exn jsoner str] decodes a JSON value from [str], then uses
    [jsoner] to construct an OCaml value. Will raise an exception if [str] is
    not a valid JSON value, or if [jsoner] cannot construct an OCaml value from
    [str]. *)

val from_string : 'a t -> string -> 'a option
(** [from_string jsoner str] decodes a JSON value from [str], then uses
    [jsoner] to construct an OCaml value. Will return [None if [str] is
    not a valid JSON value, or if [jsoner] cannot construct an OCaml value from
    [str]. *)

val conv : ('a -> 'b) -> ('b -> 'a) -> 'b t -> 'a t
(** [conv f g jsoner] crafts a new Jsoner from [jsoner]. This is typically used
    to creates a JSON encoder/decoder for OCaml records by projecting them to
    tuples, and using [objN] combinators.

    For instance,

    {[
      type t = { f1 : int; f2 : bool }
      let t_jsoner =
        conv
          (fun { f1; f2 } -> (f1, f2))
          (fun (f1, f2) -> { f1; f2 })
          (obj2 (req "f1" int) (req "f2" bool))
    ]} *)

val string_enum : (string * 'a) list -> 'a t
(** [string_enum] maps JSON strings to fixed OCaml values.

    For instance,

    {[
      type toggle = On | Off
      let toggle_jsoner = string_enum [ "on", On; "off", Off ]
    ]} *)

val string : string t
(** The Jsoner which maps JSON strings and OCaml strings. *)

val int64 : int64 t
(** The Jsoner which maps JSON ints and OCaml int64. *)

val int : int t
(** The Jsoner which maps JSON ints and OCaml ints. *)

val bool : bool t
(** The Jsoner which maps JSON booleans and OCaml booleans. *)

val list : 'a t -> 'a list t
(** [list jsoner] creates a jsoner for a list of values based on the Jsoner of
    said values. *)

type 'a field

val req : string -> 'a t -> 'a field
val opt : string -> 'a t -> 'a option field
val obj1 : 'a field -> 'a t
val obj2 : 'a field -> 'b field -> ('a * 'b) t
val obj3 : 'a field -> 'b field -> 'c field -> ('a * 'b * 'c) t
val obj4 : 'a field -> 'b field -> 'c field -> 'd field -> ('a * 'b * 'c * 'd) t

val obj5 :
  'a field ->
  'b field ->
  'c field ->
  'd field ->
  'e field ->
  ('a * 'b * 'c * 'd * 'e) t

val obj6 :
  'a field ->
  'b field ->
  'c field ->
  'd field ->
  'e field ->
  'f field ->
  ('a * 'b * 'c * 'd * 'e * 'f) t

val obj7 :
  'a field ->
  'b field ->
  'c field ->
  'd field ->
  'e field ->
  'f field ->
  'g field ->
  ('a * 'b * 'c * 'd * 'e * 'f * 'g) t

val obj8 :
  'a field ->
  'b field ->
  'c field ->
  'd field ->
  'e field ->
  'f field ->
  'g field ->
  'h field ->
  ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h) t

val obj9 :
  'a field ->
  'b field ->
  'c field ->
  'd field ->
  'e field ->
  'f field ->
  'g field ->
  'h field ->
  'i field ->
  ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i) t

val obj10 :
  'a field ->
  'b field ->
  'c field ->
  'd field ->
  'e field ->
  'f field ->
  'g field ->
  'h field ->
  'i field ->
  'j field ->
  ('a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j) t

val merge_objs : 'a t -> 'b t -> ('a * 'b) t

module Decoding : sig
  type 'a jsoner = 'a t

  type 'a t
  (** A JSON decoder. Compared to a [jsoner], this type provides the [mu]
      combinator, and a monadic DSL to write decoder. See the {!Syntax} module.
      *)

  val from_jsoner : 'a jsoner -> 'a t
  (** [from_jsoner] specializes a jsoner to be a JSON decoder. *)

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
        let open Jsoner.Decoding in
        let open Syntax in
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
        let open Jsoner.Decoding in
        let open Syntax in
        mu (fun tree_decoder ->
            let+ value = field "value" int64
            and+ children = field "children" @@ list tree_decoder in
            { value; children })
    ]}

    Here [decoder] will behave as expected.

    {v
      # Jsoner.Decoding.of_string decoder "{ \"value\": 3 , \"children\" : [] }" ;;
      - : tree option = Some {value = 3L; children = []}
      # Jsoner.Decoding.of_string decoder "{ \"value\": 3 , \"children\" : [ { \"value\": 5, \"children\": [] } ] }" ;;
      - : tree option = Some {value = 3L; children = [{value = 5L; children = []}]}
    v}*)
end
