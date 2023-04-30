(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t = Index of int | Name of string
type workspace_id = t

let decoder =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ str = string in
  match int_of_string_opt str with Some id -> Index id | None -> Name str
