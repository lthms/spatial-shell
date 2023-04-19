(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type 'a parser
(** A parser combinator which can be used to extract information from a
    [string]. *)

val return : 'a -> 'a parser
(** [return x] consumes no input and returns [x]. *)

val ( let+ ) : 'a parser -> ('a -> 'b) -> 'b parser
(** Apply a function to the result of a functor *)

val ( and+ ) : 'a parser -> 'b parser -> ('a * 'b) parser
(** Sequencially applies two parsers and returns their results. *)

val ( let* ) : 'a parser -> ('a -> 'b parser) -> 'b parser
(** The [bind] operator. *)

val ( <|> ) : 'a parser -> 'a parser -> 'a parser
(** The choice operator. *)

val ( *> ) : 'a parser -> 'b parser -> 'b parser
(** Sequencially applies two parsers and discards the result of the first one. *)

val ( <* ) : 'a parser -> 'b parser -> 'a parser
(** Sequencially applies two parsers and discards the result of the second one. *)

val string : string -> unit parser
(** [string s] tries to consume [s] from the input, fails if it cannot. *)

val char : char -> unit parser
(** [char c] tries to consume [c] from the input, fails if it cannot. *)

val int : int parser
(** Parses an integer from the input *)

val enum : (string * 'a) list -> 'a parser
val skip : 'a parser -> unit parser
val whitespaces : unit parser
val word : string -> unit parser
val empty : unit parser

val quoted : string parser
(** [quoted] consumes a string encapsulated by quotes. *)

val run : 'a parser -> string -> 'a option
