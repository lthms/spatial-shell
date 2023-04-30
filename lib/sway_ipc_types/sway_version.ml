(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t = {
  major : int64;
  minor : int64;
  patch : int64;
  human_readable : string;
  loaded_config_file_name : string;
}

type sway_version = t

let decoder =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ major = field "major" int64
  and+ minor = field "minor" int64
  and+ patch = field "patch" int64
  and+ human_readable = field "human_readable" string
  and+ loaded_config_file_name = field "loaded_config_file_name" string in
  { major; minor; patch; human_readable; loaded_config_file_name }
