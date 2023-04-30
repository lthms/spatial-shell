(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t = {
  name : string;
  capabilities : int64;
  focus : int64;
  devices : Input_device.t list;
}

type seat = t

let decoder =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ name = field "name" string
  and+ capabilities = field "capabilities" int64
  and+ focus = field "focus" int64
  and+ devices = field "devices" @@ list Input_device.decoder in
  { name; capabilities; focus; devices }
