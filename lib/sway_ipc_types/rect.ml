(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t = { x : int64; y : int64; width : int64; height : int64 }
type rect = t

let decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ x = field "x" int64
  and+ y = field "y" int64
  and+ width = field "width" int64
  and+ height = field "height" int64 in
  { x; y; width; height }
