(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type 'a t = 'a -> Ezjsonm.value

let string = Ezjsonm.string
let bool = Ezjsonm.bool
let list = Ezjsonm.list
let int64 = Ezjsonm.int64
let int = Ezjsonm.int

let field : string -> 'a t -> 'a -> Ezjsonm.value -> Ezjsonm.value =
 fun name enc value json ->
  match json with
  | `O fields -> `O ((name, enc value) :: fields)
  | _ -> raise (Invalid_argument "Json_encoder.field")

let field_opt :
    type a. string -> a t -> a option -> Ezjsonm.value -> Ezjsonm.value =
 fun name enc value json ->
  match value with Some value -> field name enc value json | None -> json

let string_enum l value =
  let rec assoc_rev x = function
    | [] -> raise Not_found
    | (a, b) :: l -> if compare b x = 0 then a else assoc_rev x l
  in
  Ezjsonm.string @@ assoc_rev value l
