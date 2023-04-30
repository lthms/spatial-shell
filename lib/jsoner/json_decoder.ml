(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type 'a t = Ezjsonm.value -> 'a

module Syntax = struct
  let ( let+ ) dec f value = f (dec value)

  let ( and+ ) x y value =
    let x = x value in
    let y = y value in
    (x, y)

  let ( let* ) dec k value =
    let x = dec value in
    k x value

  let return x _value = x
end

let field str enc value =
  try enc (Ezjsonm.find value [ str ]) with
  | Not_found -> failwith (str ^ " not found")
  | exn ->
      Format.printf "%s\n" str;
      raise exn

let field_opt str enc value =
  try
    match Ezjsonm.find_opt value [ str ] with
    | Some x -> Some (enc x)
    | None -> None
  with _exn -> None

let list enc = Ezjsonm.get_list enc
let string = Ezjsonm.get_string
let int64 = Ezjsonm.get_int64
let int = Ezjsonm.get_int

let string_enum l =
  let open Syntax in
  let+ constant = string in
  try List.assoc constant l
  with Not_found -> failwith (constant ^ " not a correct value")

let bool = Ezjsonm.get_bool
let of_string_exn dec str = Ezjsonm.value_from_string str |> dec
let of_string dec str = try Some (of_string_exn dec str) with _ -> None

let rec mu : ('a t -> 'a t) -> 'a t =
 fun f_enc value -> (f_enc (mu f_enc)) value

let float = Ezjsonm.get_float
