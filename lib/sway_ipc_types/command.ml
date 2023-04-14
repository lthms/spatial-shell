(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Format

type direction = Up | Right | Down | Left

let pp_direction fmt direction =
  pp_print_string fmt
  @@
  match direction with
  | Up -> "up"
  | Right -> "right"
  | Down -> "down"
  | Left -> "left"

type with_criteria = Move_container of string | Focus | Opacity of float
type criteria = Con_id of int64 | Focused

type t =
  | With_criteria of criteria * with_criteria
  | Focus of direction
  | Focus_output of direction
  | Focus_output_by_name of string
  | Workspace of string

let pp_criteria fmt = function
  | Con_id i -> fprintf fmt "[con_id=%Ld]" i
  | Focused -> ()

let pp_with_criteria fmt = function
  | Move_container string -> fprintf fmt "move container to workspace %s" string
  | Focus -> fprintf fmt "focus"
  | Opacity value -> fprintf fmt "opacity set %f" value

let pp fmt = function
  | With_criteria (crit, cmd) ->
      fprintf fmt "%a %a" pp_criteria crit pp_with_criteria cmd
  | Focus direction -> fprintf fmt "focus %a" pp_direction direction
  | Focus_output direction ->
      fprintf fmt "focus output %a" pp_direction direction
  | Focus_output_by_name name -> fprintf fmt "focus output %s" name
  | Workspace name -> fprintf fmt "workspace %s" name
