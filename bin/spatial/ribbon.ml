(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Sway_ipc_types

let toggle_layout =
  Spatial_ipc.(function Maximize -> Column | Column -> Maximize)

type t = {
  layout : Spatial_ipc.layout;
  column_count : int;
  hidden_left : int64 list;
  visible : (int * int64 list) option;
  hidden_right : int64 list;
}

let empty layout column_count =
  assert (0 < column_count);
  { layout; column_count; hidden_left = []; visible = None; hidden_right = [] }

let column_count ribbon = ribbon.column_count
let layout ribbon = ribbon.layout

let visible_windows_count = function
  | { visible = None; _ } -> 0
  | { visible = Some (f, l); _ } ->
      assert (0 <= f && f < List.length l);
      List.length l

let rec insert_at n a = function
  | l when n = 0 -> a :: l
  | x :: rst when 0 < n -> x :: insert_at (n - 1) a rst
  | _ -> raise (Invalid_argument "insert_at")

let push_front x l = x :: l
let pop_front = function x :: l -> Some (x, l) | [] -> None

let pop_front_exn l =
  match pop_front l with
  | Some res -> res
  | None -> raise (Invalid_argument "pop_front_exn")

let push_back x l = List.rev l |> push_front x |> List.rev

let pop_back l =
  List.rev l |> pop_front |> Option.map (fun (x, l) -> (x, List.rev l))

let pop_back_exn l =
  match pop_back l with
  | Some res -> res
  | None -> raise (Invalid_argument "pop_back_exn")

let shrink_left ribbon =
  match ribbon.visible with
  | Some (0, _) when ribbon.column_count < visible_windows_count ribbon ->
      raise (Invalid_argument "shrink_left")
  | Some (f, l) when ribbon.column_count < visible_windows_count ribbon ->
      let w, l = pop_front_exn l in
      {
        ribbon with
        visible = Some (f - 1, l);
        hidden_left = push_front w ribbon.hidden_left;
      }
  | _ -> ribbon

let shrink_right ribbon =
  match ribbon.visible with
  | Some (f, l)
    when ribbon.column_count < visible_windows_count ribbon
         && f + 1 = List.length l ->
      raise (Invalid_argument "shrink_right")
  | Some (f, l) when ribbon.column_count < visible_windows_count ribbon ->
      let w, l = pop_back_exn l in
      {
        ribbon with
        visible = Some (f, l);
        hidden_right = push_front w ribbon.hidden_right;
      }
  | _ -> ribbon

let shrink ribbon =
  match ribbon.visible with
  | Some (f, _) when 0 < f -> shrink_left ribbon
  | Some (f, l) when f < List.length l - 1 -> shrink_right ribbon
  | _ -> ribbon

let insert_window window ribbon =
  match ribbon.visible with
  | None -> { ribbon with visible = Some (0, [ window ]) }
  | Some (f, l) ->
      let f = f + 1 in
      let ribbon = { ribbon with visible = Some (f, insert_at f window l) } in
      if f < ribbon.column_count then shrink_right ribbon
      else shrink_left ribbon

let remove window =
  let rec remove idx acc = function
    | x :: rst when window = x -> Some (idx, List.rev acc @ rst)
    | x :: rst -> remove (idx + 1) (x :: acc) rst
    | [] -> None
  in
  remove 0 []

let remove_if_present window =
  let rec remove acc = function
    | x :: rst when window = x -> List.rev acc @ rst
    | x :: rst -> remove (x :: acc) rst
    | [] -> List.rev acc
  in
  remove []

let fill_space ribbon =
  if visible_windows_count ribbon < ribbon.column_count then
    match
      ( pop_front ribbon.hidden_right,
        pop_front ribbon.hidden_left,
        ribbon.visible )
    with
    | Some (x, hidden_right), _, Some (f, l) ->
        { ribbon with visible = Some (f, push_back x l); hidden_right }
    | Some (x, hidden_right), _, None ->
        { ribbon with visible = Some (0, [ x ]); hidden_right }
    | None, Some (x, hidden_left), Some (f, l) ->
        { ribbon with visible = Some (f + 1, push_front x l); hidden_left }
    | None, Some (x, hidden_left), None ->
        { ribbon with visible = Some (0, [ x ]); hidden_left }
    | None, None, _ -> ribbon
  else ribbon

let incr_maximum_visible ribbon =
  fill_space { ribbon with column_count = ribbon.column_count + 1 }

let decr_maximum_visible ribbon =
  if 2 < ribbon.column_count then
    shrink { ribbon with column_count = ribbon.column_count - 1 }
  else ribbon

let remove_window window ribbon =
  fill_space
  @@
  match ribbon.visible with
  | Some (f, l) -> (
      match remove window l with
      | Some (_, []) -> { ribbon with visible = None }
      | Some (_, l) ->
          let f' = if f < List.length l then f else f - 1 in
          { ribbon with visible = Some (f', l) }
      | None ->
          {
            ribbon with
            hidden_left = remove_if_present window ribbon.hidden_left;
            hidden_right = remove_if_present window ribbon.hidden_right;
          })
  | None ->
      {
        ribbon with
        hidden_left = remove_if_present window ribbon.hidden_left;
        hidden_right = remove_if_present window ribbon.hidden_right;
      }

let toggle_layout ribbon = { ribbon with layout = toggle_layout ribbon.layout }

let move_focus_left ribbon =
  match ribbon.visible with
  | None -> ribbon
  | Some (0, l) -> (
      match pop_front ribbon.hidden_left with
      | Some (x, hidden_left) ->
          shrink_right
            { ribbon with visible = Some (0, push_front x l); hidden_left }
      | None -> ribbon)
  | Some (f, l) -> { ribbon with visible = Some (f - 1, l) }

let move_focus_right ribbon =
  match ribbon.visible with
  | None -> ribbon
  | Some (f, l) when f < List.length l - 1 ->
      { ribbon with visible = Some (f + 1, l) }
  | Some (f, l) -> (
      match pop_front ribbon.hidden_right with
      | Some (x, hidden_right) ->
          shrink_left
            { ribbon with visible = Some (f + 1, push_back x l); hidden_right }
      | None -> ribbon)

let focus_index ribbon index =
  let index = index - List.length ribbon.hidden_left in
  let rec aux ribbon index =
    match ribbon.visible with
    | Some (_, l) ->
        let visible_len = List.length l in
        if index < 0 then
          aux (move_focus_left { ribbon with visible = Some (0, l) }) (index + 1)
        else if index < visible_len then
          { ribbon with visible = Some (index, l) }
        else if index < visible_len + List.length ribbon.hidden_right then
          aux
            (move_focus_right
               { ribbon with visible = Some (visible_len - 1, l) })
            (index - 1)
        else ribbon
    | _ -> ribbon
  in
  aux ribbon index

let focus_window ribbon window =
  let rec find ofs = function
    | [] -> None
    | x :: _ when x = window -> Some ofs
    | _ :: rst -> find (ofs + 1) rst
  in
  let find = find 0 in
  let rec repeat n s f = if n = 0 then s else repeat (n - 1) (f s) f in
  match ribbon.visible with
  | Some (f, l) -> (
      match find l with
      | Some target ->
          if f = target then ribbon
          else if f < target then repeat (target - f) ribbon move_focus_right
          else repeat (f - target) ribbon move_focus_left
      | None -> ribbon)
  | None -> ribbon

let split_at l i =
  let rec split_visible acc i = function
    | x :: rst when i = 0 -> Some (List.rev acc, x, rst)
    | x :: rst -> split_visible (x :: acc) (i - 1) rst
    | [] -> raise (Invalid_argument "Ribbon.split_at")
  in
  split_visible [] i l

let split_visible ribbon =
  match ribbon.visible with None -> None | Some (f, l) -> split_at l f

let move_window_left ribbon =
  match split_visible ribbon with
  | Some (left, focus, right) -> (
      match pop_back left with
      | Some (x, left) ->
          (* Case:   [.. |a b {f} ..| ..]
             Result: [.. |a {f} b ..| ..] *)
          {
            ribbon with
            visible =
              Some (List.length left, left @ [ focus ] @ push_front x right);
          }
      | None -> (
          (* Case:   [.. |{f} ..| ..] *)
          match pop_front ribbon.hidden_left with
          | Some (x, hidden_left) ->
              (* Case:   [.. a |{f} ..| ..] *)
              (* Result: [.. |{f} a ..| ..] *)
              {
                ribbon with
                visible = Some (0, focus :: push_front x right);
                hidden_left;
              }
              |> shrink_right
          | None ->
              (* Case:   [|{f} ..| ..] *)
              ribbon))
  (* Case:   [||]
     Result: [||] *)
  | None -> ribbon

let move_window_right ribbon =
  match split_visible ribbon with
  | Some (left, focus, right) -> (
      let f = List.length left + 1 in
      match pop_front right with
      | Some (x, right) ->
          (* Case:   [.. |.. {f} a b| ..]
             Result: [.. |.. a {f} b| ..] *)
          {
            ribbon with
            visible = Some (f, push_back x left @ [ focus ] @ right);
          }
      | None -> (
          (* Case:   [.. |.. {f}| ..] *)
          match pop_front ribbon.hidden_right with
          | Some (x, hidden_right) ->
              (* Case:   [  |.. {f}| a b] *)
              (* Result: [  |.. a {f}| b] *)
              {
                ribbon with
                visible = Some (f, push_back x left @ [ focus ] @ right);
                hidden_right;
              }
              |> shrink_left
          | None ->
              (* Case:   [.. |.. {f}|] *)
              ribbon))
  (* Case:   [||]
     Result: [||] *)
  | None -> ribbon

let hide_window_command window =
  let target = Format.sprintf "*%Ld*" window in
  Command.With_criteria (Con_id window, Move_container target)

let show_window_command workspace window =
  [
    Command.With_criteria (Con_id window, Move_container workspace);
    Command.With_criteria (Con_id window, Focus);
  ]

let visible_windows_summary ribbon = ribbon.visible

let visible_windows ribbon =
  match ribbon.visible with
  | Some (f, l) when ribbon.layout = Maximize -> [ List.nth l f ]
  | Some (_, l) -> l
  | None -> []

let all_windows ribbon =
  List.rev ribbon.hidden_left
  @ visible_windows { ribbon with layout = Column }
  @ ribbon.hidden_right

let windows_summary ribbon =
  match ribbon.visible with
  | Some (f, _) -> Some (f + List.length ribbon.hidden_left, all_windows ribbon)
  | None -> None

let focused_window ribbon =
  match ribbon.visible with Some (f, l) -> List.nth_opt l f | None -> None

let hide_all_windows_commands ribbon =
  List.map hide_window_command @@ all_windows ribbon

let show_visible_windows_commands workspace ribbon =
  match ribbon.visible with
  | Some (f, l) when ribbon.layout = Maximize ->
      show_window_command workspace (List.nth l f)
  | Some (_, l) -> List.concat_map (show_window_command workspace) l
  | None -> []

let focus_command ribbon =
  List.concat_map
    (fun x ->
      [
        Command.With_criteria (Con_id x, Focus);
        With_criteria (Con_id x, Opacity 1.0);
      ])
    (Option.to_list @@ focused_window ribbon)

(* TODO: Decide if we really do need [force_focus]. *)
let arrange_commands ?force_focus workspace ribbon =
  let hide_commands = hide_all_windows_commands ribbon in
  let show_commands = show_visible_windows_commands workspace ribbon in
  let focus_commands =
    focus_command ribbon
    @
    match force_focus with
    | Some w -> [ Command.With_criteria (Con_id w, Focus) ]
    | _ -> []
  in
  hide_commands @ show_commands @ focus_commands

let pp fmt ribbon =
  match split_visible ribbon with
  | None -> Format.fprintf fmt "[]"
  | Some (left, x, right) ->
      Format.fprintf fmt "[%a|%a{%Ld}%a|%a]" Pp_helpers.pp_windows_seq
        (List.rev ribbon.hidden_left)
        Pp_helpers.pp_windows_seq left x Pp_helpers.pp_windows_seq right
        Pp_helpers.pp_windows_seq ribbon.hidden_right
