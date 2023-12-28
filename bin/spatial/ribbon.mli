(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t

val empty : Spatial_ipc.layout -> int -> t
val layout : t -> Spatial_ipc.layout
val column_count : t -> int
val visible_windows_summary : t -> (int * int64 list) option
val windows_summary : t -> (int * int64 list) option
val insert_window : int64 -> t -> t
val remove_window : int64 -> t -> t
val incr_maximum_visible : t -> t
val decr_maximum_visible : t -> t
val move_focus_left : t -> t
val move_focus_right : t -> t
val move_window_left : t -> t
val move_window_right : t -> t
val focus_window : t -> int64 -> t
val focus_index : t -> int -> t
val toggle_layout : t -> t

val arrange_commands :
  ?force_focus:int64 -> string -> t -> Sway_ipc_types.Command.t list

val pp : Format.formatter -> t -> unit
