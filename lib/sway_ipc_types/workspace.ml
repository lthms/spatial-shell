(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t = {
  num : int64;
  name : string;
  visible : bool;
  focused : bool;
  urgent : bool;
  rect : Rect.t;
  output : string;
}

type workspace = t

let decoder =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ num = field "num" int64
  and+ name = field "name" string
  and+ visible = field "visible" bool
  and+ focused = field "focused" bool
  and+ urgent = field "urgent" bool
  and+ rect = field "rect" Rect.decoder
  and+ output = field "output" string in
  { num; name; visible; focused; urgent; rect; output }
