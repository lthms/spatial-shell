type t = Index of int | Name of string
type workspace_id = t

let decoder =
  let open Json_decoder in
  let open Syntax in
  let+ str = string in
  match int_of_string_opt str with Some id -> Index id | None -> Name str
