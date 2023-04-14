(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type event_type =
  | Workspace
  | Mode
  | Window
  | Barconfig_update
  | Binding
  | Shutdown
  | Tick
  | Bar_state_update
  | Input

let event_type_code = function
  | Workspace -> 0x80000000l
  | Mode -> 0x80000002l
  | Window -> 0x80000003l
  | Barconfig_update -> 0x80000004l
  | Binding -> 0x80000005l
  | Shutdown -> 0x80000006l
  | Tick -> 0x80000007l
  | Bar_state_update -> 0x80000014l
  | Input -> 0x80000015l

let event_type_of_code = function
  | 0x80000000l -> Workspace
  | 0x80000002l -> Mode
  | 0x80000003l -> Window
  | 0x80000004l -> Barconfig_update
  | 0x80000005l -> Binding
  | 0x80000006l -> Shutdown
  | 0x80000007l -> Tick
  | 0x80000014l -> Bar_state_update
  | 0x80000015l -> Input
  | _ -> raise (Invalid_argument "event_type_of_code")

let event_type_decoder =
  Json_decoder.string_enum
    [
      ("workspace", Workspace);
      ("mode", Mode);
      ("window", Window);
      ("barconfig_update", Barconfig_update);
      ("binding", Binding);
      ("shutdown", Shutdown);
      ("tick", Tick);
      ("bar_state_update", Bar_state_update);
      ("input", Input);
    ]

let event_type_string = function
  | Workspace -> "workspace"
  | Mode -> "mode"
  | Window -> "window"
  | Barconfig_update -> "barconfig_update"
  | Binding -> "binding"
  | Shutdown -> "shutdown"
  | Tick -> "tick"
  | Bar_state_update -> "bar_state_update"
  | Input -> "input"

type workspace_change = Init | Empty | Focus | Move | Rename | Urgent | Reload

let workspace_change_decoder =
  Json_decoder.string_enum
    [
      ("init", Init);
      ("empty", Empty);
      ("focus", Focus);
      ("move", Move);
      ("rename", Rename);
      ("urgent", Urgent);
      ("reload", Reload);
    ]

type workspace_event = {
  change : workspace_change;
  current : Node.t;
  old : Node.t option;
}

let workspace_event_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ change = field "change" workspace_change_decoder
  and+ current = field "current" Node.decoder
  and+ old = field_opt "old" Node.decoder in
  { change; current; old }

type mode_event = { change : string; pango_markup : bool }

let mode_event_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ change = field "change" string
  and+ pango_markup = field "pango_markup" bool in
  { change; pango_markup }

type window_change =
  | New
  | Close
  | Focus
  | Title
  | Fullscreen_mode
  | Move
  | Floating
  | Urgent
  | Mark

let window_change_decoder =
  Json_decoder.string_enum
    [
      ("new", New);
      ("close", Close);
      ("focus", Focus);
      ("title", Title);
      ("fullscreen_mode", Fullscreen_mode);
      ("move", Move);
      ("floating", Floating);
      ("urgent", Urgent);
      ("mark", Mark);
    ]

type window_event = { change : window_change; container : Node.t }

let window_event_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ change = field "change" window_change_decoder
  and+ container = field "container" Node.decoder in
  { change; container }

type tick_event = { first : bool; payload : string }

let tick_event_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ first = field "first" bool and+ payload = field "payload" string in
  { first; payload }

type t =
  | Workspace of workspace_event
  | Mode of mode_event
  | Window of window_event

type event = t

let decoder (code : event_type) =
  let open Json_decoder in
  let open Syntax in
  match code with
  | Workspace ->
      let+ ev = workspace_event_decoder in
      Workspace ev
  | Mode ->
      let+ ev = mode_event_decoder in
      Mode ev
  | Window ->
      let+ ev = window_event_decoder in
      Window ev
  | _ -> assert false

let event_of_raw_message (opc, payload) =
  let ev = event_type_of_code opc in
  Json_decoder.of_string_exn (decoder ev) payload
