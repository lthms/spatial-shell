(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type subpixel_hinting = Rgb | Bgr | Vrgb | Vbgr | None | Unknown

let subpixel_hinting_decoder =
  Jsoner.Decoding.string_enum
    [
      ("rgb", Rgb);
      ("bgr", Bgr);
      ("vrgb", Vrgb);
      ("none", None);
      ("unknown", Unknown);
    ]

type transform =
  | Normal
  | Ninety
  | One_eighty
  | Two_seventy
  | Flipped_ninety
  | Flipped_one_eighty
  | Flipped_two_seventy

let transform_decoder =
  Jsoner.Decoding.string_enum
    [
      ("normal", Normal);
      ("90", Ninety);
      ("180", One_eighty);
      ("270", Two_seventy);
      ("flipped-90", Flipped_ninety);
      ("flipped-180", Flipped_one_eighty);
      ("flipped-270", Flipped_two_seventy);
    ]

type mode = { width : int64; height : int64; refresh : int64 }

let mode_decoder =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ width = field "width" int64
  and+ height = field "height" int64
  and+ refresh = field "refresh" int64 in
  { width; height; refresh }

type orientation = Vertical | Horizontal | None

let orientation_decoder =
  Jsoner.Decoding.string_enum
    [ ("vertical", Vertical); ("horizontal", Horizontal); ("none", None) ]

type t = {
  name : string;
  make : string;
  model : string;
  serial : string;
  active : bool;
  dpms : bool;
  primary : bool;
  scale : float option;
  subpixel_hinting : subpixel_hinting option;
  transform : transform option;
  current_workspace : Workspace_id.t option;
  modes : mode list;
  current_mode : mode option;
  rect : Rect.t;
}

type output = t

let decoder =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ name = field "name" string
  and+ make = field "make" string
  and+ model = field "model" string
  and+ serial = field "serial" string
  and+ active = field "active" bool
  and+ dpms = field "dpms" bool
  and+ primary = field "primary" bool
  and+ scale = field_opt "scale" float
  and+ subpixel_hinting = field_opt "subpixel_hinting" subpixel_hinting_decoder
  and+ transform = field_opt "transform" transform_decoder
  and+ current_workspace = field_opt "current_workspace" Workspace_id.decoder
  and+ modes = field "modes" @@ list mode_decoder
  and+ current_mode = field_opt "current_mode" mode_decoder
  and+ rect = field "rect" Rect.decoder in
  {
    name;
    make;
    model;
    serial;
    active;
    dpms;
    primary;
    scale;
    subpixel_hinting;
    transform;
    current_workspace;
    modes;
    current_mode;
    rect;
  }
