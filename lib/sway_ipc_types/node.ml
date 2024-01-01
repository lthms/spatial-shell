(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type fullscreen_mode =
  | None
  (* 0 *)
  | Full_workspace
  (* 1 *)
  | Global_fullscreen (* 2 *)

let fullscreen_mode_decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ i = int64 in
  match i with
  | 0L -> None
  | 1L -> Full_workspace
  | 2L -> Global_fullscreen
  | _ -> raise (Invalid_argument "fullscreen_mode_decoder")

type node_type = Root | Output | Workspace | Con | Floating_con

let node_type_decoder =
  Ezjsonm_encoding.Decoding.string_enum
    [
      ("root", Root);
      ("output", Output);
      ("workspace", Workspace);
      ("con", Con);
      ("floating_con", Floating_con);
    ]

type border = Normal | None | Pixel | Csd

let border_decoder =
  Ezjsonm_encoding.Decoding.string_enum
    [ ("normal", Normal); ("none", None); ("pixel", Pixel); ("csd", Csd) ]

type layout =
  | Split_horizontal
  | Split_vertical
  | Stacked
  | Tabbed
  | Output
  | None

let layout_decoder =
  Ezjsonm_encoding.Decoding.string_enum
    [
      ("splith", Split_horizontal);
      ("splitv", Split_vertical);
      ("stacked", Stacked);
      ("tabbed", Tabbed);
      ("output", Output);
      ("none", None);
    ]

type mark = string

let mark_decoder = Ezjsonm_encoding.Decoding.string

type application_state = Enabled | None

let application_state_decoder =
  Ezjsonm_encoding.Decoding.string_enum [ ("enabled", Enabled); ("none", None) ]

type user_state = Focus | Fullscreen | Open | Visible | None

let user_state_decoder =
  Ezjsonm_encoding.Decoding.string_enum
    [
      ("focus", Focus);
      ("fullscreen", Fullscreen);
      ("open", Open);
      ("visible", Visible);
      ("none", None);
    ]

type idle_inhibitors = { application : application_state; user : user_state }

let idle_inhibitors_decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ application = application_state_decoder and+ user = user_state_decoder in
  { application; user }

type window_properties = {
  title : string;
  window_class : string;
  instance : string;
  window_role : string option;
  window_type : string option;
  transient_for : string option;
}

let window_properties_decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ title = field "title" string
  and+ window_class = field "window_class" string
  and+ instance = field "instance" string
  and+ window_role = field_opt "window_class" string
  and+ window_type = field_opt "window_type" string
  and+ transient_for = field_opt "transient_for" string in
  { title; window_class; instance; window_role; window_type; transient_for }

type t = {
  id : int64;
  name : string option;
  node_type : node_type;
  border : border;
  current_border_width : int64;
  layout : layout;
  orientation : Output.orientation;
  percent : float option;
  rect : Rect.t;
  window_rect : Rect.t;
  deco_rect : Rect.t;
  geometry : Rect.t;
  urgent : bool;
  sticky : bool;
  marks : mark list;
  focused : bool;
  focus : int64 list;
  nodes : t list;
  floating_nodes : t list;
  representation : string option;
  fullscreen_mode : fullscreen_mode option;
  app_id : string option;
  pid : int64 option;
  visible : bool option;
  shell : string option;
  inhibit_idle : bool option;
  idle_inhibitors : idle_inhibitors option;
  window : int64 option;
  window_properties : window_properties option;
}

type node = t

let decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  mu (fun node_decoder ->
      let+ id = field "id" int64
      and+ name = field_opt "name" string
      and+ node_type = field "type" node_type_decoder
      and+ border = field "border" border_decoder
      and+ current_border_width = field "current_border_width" int64
      and+ layout = field "layout" layout_decoder
      and+ orientation = field "orientation" Output.orientation_decoder
      and+ percent = field_opt "percent" float
      and+ rect = field "rect" Rect.decoder
      and+ window_rect = field "window_rect" Rect.decoder
      and+ deco_rect = field "deco_rect" Rect.decoder
      and+ geometry = field "geometry" Rect.decoder
      and+ urgent = field "urgent" bool
      and+ sticky = field "sticky" bool
      and+ marks = field "marks" @@ list mark_decoder
      and+ focused = field "focused" bool
      and+ focus = field "focus" @@ list int64
      and+ nodes = field "nodes" @@ list node_decoder
      and+ floating_nodes = field "floating_nodes" @@ list node_decoder
      and+ representation = field_opt "representation" string
      and+ fullscreen_mode = field_opt "fullscreen_mode" fullscreen_mode_decoder
      and+ app_id = field_opt "app_id" string
      and+ pid = field_opt "pid" int64
      and+ visible = field_opt "visible" bool
      and+ shell = field_opt "shell" string
      and+ inhibit_idle = field_opt "inhibit_idle" bool
      and+ idle_inhibitors = field_opt "idle_inhibitors" idle_inhibitors_decoder
      and+ window = field_opt "window" int64
      and+ window_properties =
        field_opt "window_properties" window_properties_decoder
      in
      {
        id;
        name;
        node_type;
        border;
        current_border_width;
        orientation;
        layout;
        percent;
        rect;
        window_rect;
        deco_rect;
        geometry;
        urgent;
        sticky;
        marks;
        focused;
        nodes;
        floating_nodes;
        representation;
        fullscreen_mode;
        app_id;
        pid;
        visible;
        shell;
        inhibit_idle;
        window;
        window_properties;
        focus;
        idle_inhibitors;
      })

let rec fold acc f node =
  let acc = f acc node in
  let acc = List.fold_left (fun acc node -> fold acc f node) acc node.nodes in
  let acc =
    List.fold_left (fun acc node -> fold acc f node) acc node.floating_nodes
  in
  acc

let rec filter f node =
  List.concat
    [
      (if f node then [ node ] else []);
      List.concat_map (fun x -> filter f x) node.nodes;
      List.concat_map (fun x -> filter f x) node.floating_nodes;
    ]

let rec find f node = find_first f ((node :: node.nodes) @ node.floating_nodes)

and find_first f = function
  | x :: rst ->
      if f x then Some x else find_first f (x.nodes @ x.floating_nodes @ rst)
  | [] -> None

let find_workspace_by_name name root =
  find (fun x -> x.name = name && x.node_type == Root) root

let is_window node = Option.is_some node.pid
