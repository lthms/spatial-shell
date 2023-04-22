(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Spatial_ipc
module Map = Map.Make (Int64)

type window_info = { workspace : string; window : window }
type t = window_info Map.t

let empty : t = Map.empty
let register : int64 -> window_info -> t -> t = Map.add
let unregister = Map.remove
let find = Map.find
let find_opt = Map.find_opt
let update = Map.update

let change_workspace window workspace map =
  update window
    (function Some info -> Some { info with workspace } | None -> None)
    map

let pp_window fmt (id, { workspace; window = { name; app_id } }) =
  Format.fprintf fmt "{ id = %Ld; app_id = %s; name = %s; workspace = %s }" id
    name app_id workspace

let pp fmt windows =
  let open Format in
  fprintf fmt "%a"
    (pp_print_list ~pp_sep:(fun fmt () -> pp_print_string fmt ", ") pp_window)
    (Map.to_seq windows |> List.of_seq)
