(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Sway_ipc_types
module Workspaces_map = Stdlib.Map.Make (String)
module Workspaces_set = Stdlib.Set.Make (String)

type t = {
  outdated_workspaces : Workspaces_set.t;
  current_workspace : string;
  windows : Windows_registry.t;
  workspaces : Workspaces_registry.t;
  default_layout : Spatial_ipc.layout;
  default_layout_per_workspace : Spatial_ipc.layout Workspaces_map.t;
  default_column_count : int;
  default_column_count_per_workspace : int Workspaces_map.t;
  ignore_events : int;
  status_bar_name : string option;
}

type workspace_reorg =
  | Full  (** Rearrange containers based on Spatial state *)
  | Light  (** Only signal bar *)
  | None  (** Nothing to do *)

let needs_signal = function Full | Light -> true | None -> false
let needs_arranging = function Full -> true | Light | None -> false

type update = {
  state : t;
  workspace_reorg : workspace_reorg;
  force_focus : int64 option;
}

let no_visible_update state =
  { state; workspace_reorg = None; force_focus = None }

let empty current_workspace =
  {
    outdated_workspaces = Workspaces_set.empty;
    current_workspace;
    windows = Windows_registry.empty;
    workspaces = Workspaces_registry.empty;
    default_layout = Column;
    default_layout_per_workspace = Workspaces_map.empty;
    default_column_count = 2;
    default_column_count_per_workspace = Workspaces_map.empty;
    ignore_events = 0;
    status_bar_name = None;
  }

let push_ignore_events state =
  { state with ignore_events = state.ignore_events + 1 }

let pop_ignore_events state =
  { state with ignore_events = state.ignore_events - 1 }

let ignore_events state = 0 < state.ignore_events

let default_layout { default_layout; default_layout_per_workspace; _ } workspace
    =
  match Workspaces_map.find_opt workspace default_layout_per_workspace with
  | Some x -> x
  | None -> default_layout

let default_column_count
    { default_column_count; default_column_count_per_workspace; _ } workspace =
  match
    Workspaces_map.find_opt workspace default_column_count_per_workspace
  with
  | Some x -> x
  | None -> default_column_count

let internal_register_window state target_workspace window =
  Workspaces_registry.register_window
    (default_layout state target_workspace)
    (default_column_count state target_workspace)
    target_workspace window

let set_current_workspace current_workspace state =
  let is_outdated =
    Workspaces_set.mem current_workspace state.outdated_workspaces
  in
  ( {
      state with
      current_workspace;
      outdated_workspaces =
        Workspaces_set.remove current_workspace state.outdated_workspaces;
    },
    is_outdated )

let focus_index workspace state index =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.focus_index ribbon index) | None -> None)
        state.workspaces;
  }

let toggle_layout workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.toggle_layout ribbon)
          | None ->
              Some
                Ribbon.(
                  toggle_layout
                  @@ empty
                       (default_layout state state.current_workspace)
                       (default_column_count state state.current_workspace)))
        state.workspaces;
  }

let move_window_right workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.move_window_right ribbon) | None -> None)
        state.workspaces;
  }

let move_window_in_workspace target_workspace state =
  let current_workspace = state.current_workspace in
  match target_workspace current_workspace with
  | Some target_workspace -> (
      let current_ribbon =
        Workspaces_registry.find_opt current_workspace state.workspaces
      in
      match current_ribbon with
      | Some ribbon -> (
          match Ribbon.visible_windows_summary ribbon with
          | Some (f, l) ->
              let window = List.nth l f in
              let ribbon = Ribbon.remove_window window ribbon in
              {
                state with
                outdated_workspaces =
                  Workspaces_set.add current_workspace state.outdated_workspaces;
                windows =
                  Windows_registry.change_workspace window target_workspace
                    state.windows;
                current_workspace = target_workspace;
                workspaces =
                  Workspaces_registry.add current_workspace ribbon
                    state.workspaces
                  |> internal_register_window state target_workspace window;
              }
          | None -> state)
      | None -> state)
  | None -> state

let move_window_up =
  move_window_in_workspace (fun current ->
      match int_of_string_opt current with
      | Some x when 1 < x -> Some (string_of_int (x - 1))
      | _ -> None)

let move_window_down =
  move_window_in_workspace (fun current ->
      match int_of_string_opt current with
      (* TODO: 6 should be configurable *)
      | Some x when x < 6 -> Some (string_of_int (x + 1))
      | _ -> None)

let move_window_exact x =
  move_window_in_workspace (fun _current ->
      (* TODO: 6 should be configurable *)
      if x < 6 then Some (string_of_int x) else None)

let move_window_left workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.move_window_left ribbon) | None -> None)
        state.workspaces;
  }

let incr_maximum_visible_size workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.incr_maximum_visible ribbon)
          | None ->
              Some
                Ribbon.(
                  incr_maximum_visible
                  @@ empty
                       (default_layout state state.current_workspace)
                       (default_column_count state state.current_workspace)))
        state.workspaces;
  }

let decr_maximum_visible_size workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.decr_maximum_visible ribbon)
          | None ->
              Some
                Ribbon.(
                  decr_maximum_visible
                  @@ empty
                       (default_layout state state.current_workspace)
                       (default_column_count state state.current_workspace)))
        state.workspaces;
  }

let arrange_workspace_commands ?previous_state ?force_focus workspace state =
  let change_workspace =
    match previous_state with
    | Some previous_state ->
        if previous_state.current_workspace <> state.current_workspace then
          [ Sway_ipc_types.Command.Workspace state.current_workspace ]
        else []
    | None -> []
  in
  let update_workspace =
    match Workspaces_registry.find_opt workspace state.workspaces with
    | Some ribbon -> Ribbon.arrange_commands ?force_focus workspace ribbon
    | None -> []
  in
  change_workspace @ update_workspace

let arrange_workspace ?previous_state ?force_focus ~socket workspace state =
  let cmds =
    arrange_workspace_commands ?previous_state ?force_focus workspace state
  in
  let _reply = Sway_ipc.send_tick ~socket "spatial:on" in
  let _replies = Sway_ipc.send_command ~socket (Run_command cmds) in
  let _reply = Sway_ipc.send_tick ~socket "spatial:off" in
  ()

let arrange_current_workspace ?previous_state ?force_focus state =
  Sway_ipc.with_socket (fun socket ->
      arrange_workspace ?previous_state ?force_focus ~socket
        state.current_workspace state)

let register_window workspace state (tree : Node.t) =
  match tree.node_type with
  | Con ->
      let id = tree.id in
      let app_id = Option.value ~default:"" tree.app_id in
      let name = Option.value ~default:"" tree.name in
      {
        state with
        workspaces =
          internal_register_window state workspace id state.workspaces;
        windows =
          Windows_registry.register id
            { workspace; window = { app_id; name } }
            state.windows;
      }
  | _ -> state

let record_window_title_change state (node : Node.t) =
  {
    state with
    windows =
      Windows_registry.update node.id
        (function
          | Some info ->
              Some
                Windows_registry.
                  {
                    info with
                    window =
                      {
                        info.window with
                        name = Option.value ~default:"" node.name;
                      };
                  }
          | None -> None)
        state.windows;
  }

let record_focus_change state window =
  {
    state with
    workspaces =
      Workspaces_registry.update state.current_workspace
        (function
          | Some ribbon -> Some (Ribbon.focus_window ribbon window)
          | None -> None)
        state.workspaces;
  }

let unregister_window state window =
  match Windows_registry.find_opt window state.windows with
  | Some info ->
      let windows = Windows_registry.unregister window state.windows in
      let outdated_workspaces =
        if state.current_workspace <> info.workspace then
          Workspaces_set.add info.workspace state.outdated_workspaces
        else state.outdated_workspaces
      in
      let workspaces =
        Workspaces_registry.update info.workspace
          (function
            | Some ribbon -> Some (Ribbon.remove_window window ribbon)
            | None -> None)
          state.workspaces
      in
      { state with windows; workspaces; outdated_workspaces }
  | None -> state

(* TODO: Make it configurable *)
let max_workspace = 6

let send_command_workspace dir state =
  (match (dir, int_of_string_opt state.current_workspace) with
  | `Next, Some x when x < max_workspace -> Some (x + 1)
  | `Prev, Some x when 1 < x -> Some (x - 1)
  | (`Next | `Prev), Some _ -> None
  | (`Next | `Prev), None -> Some 0
  | `Exact x, _ when x <= max_workspace -> Some x
  | `Exact _, _ -> None)
  |> function
  | Some target ->
      ignore
      @@ Sway_ipc.send_command
           (Run_command [ Workspace (string_of_int target) ])
  | None -> ()

let client_command_handle : type a. t -> a Spatial_ipc.t -> update * a =
 fun state cmd ->
  let open Spatial_ipc in
  (match cmd with
   | Run_command cmd ->
       let res =
         match cmd with
         | Default_layout (None, default_layout) ->
             let state = { state with default_layout } in
             no_visible_update state
         | Default_layout (Some ws, default_layout) ->
             let state =
               {
                 state with
                 default_layout_per_workspace =
                   Workspaces_map.add (string_of_int ws) default_layout
                     state.default_layout_per_workspace;
               }
             in
             no_visible_update state
         | Default_column_count (None, default_column_count) ->
             let state = { state with default_column_count } in
             no_visible_update state
         | Default_column_count (Some ws, default_column_count) ->
             let state =
               {
                 state with
                 default_column_count_per_workspace =
                   Workspaces_map.add (string_of_int ws) default_column_count
                     state.default_column_count_per_workspace;
               }
             in
             no_visible_update state
         | Focus Left ->
             let state =
               {
                 state with
                 workspaces =
                   Workspaces_registry.update state.current_workspace
                     (function
                       | Some ribbon -> Some (Ribbon.move_focus_left ribbon)
                       | None -> None)
                     state.workspaces;
               }
             in
             { state; workspace_reorg = Full; force_focus = None }
         | Focus Right ->
             let state =
               {
                 state with
                 workspaces =
                   Workspaces_registry.update state.current_workspace
                     (function
                       | Some ribbon -> Some (Ribbon.move_focus_right ribbon)
                       | None -> None)
                     state.workspaces;
               }
             in
             { state; workspace_reorg = Full; force_focus = None }
         | Window x ->
             let state = focus_index state.current_workspace state x in
             { state; workspace_reorg = Full; force_focus = None }
         | Focus Up ->
             (* Don’t update the state, but ask Sway to change the
                current workspace instead. This will trigger an event
                that we will eventually received. *)
             send_command_workspace `Prev state;
             no_visible_update state
         | Focus Down ->
             (* Don’t update the state, but ask Sway to change the
                current workspace instead. This will trigger an event
                that we will eventually received. *)
             send_command_workspace `Next state;
             no_visible_update state
         | Focus (Workspace x) ->
             (* Don’t update the state, but ask Sway to change the
                current workspace instead. This will trigger an event
                that we will eventually received. *)
             send_command_workspace (`Exact x) state;
             no_visible_update state
         | Move Left ->
             let state = move_window_left state.current_workspace state in
             { state; workspace_reorg = Full; force_focus = None }
         | Move Right ->
             let state = move_window_right state.current_workspace state in
             { state; workspace_reorg = Full; force_focus = None }
         | Move Up ->
             let state = move_window_up state in
             { state; workspace_reorg = Full; force_focus = None }
         | Move Down ->
             let state = move_window_down state in
             { state; workspace_reorg = Full; force_focus = None }
         | Move (Workspace x) ->
             let state = move_window_exact x state in
             { state; workspace_reorg = Full; force_focus = None }
         | Toggle_layout ->
             let state = toggle_layout state.current_workspace state in
             { state; workspace_reorg = Full; force_focus = None }
         | Layout _ ->
             (* TODO: implement [On] and [Off] cases *)
             no_visible_update state
         | Column_count Incr ->
             let state =
               incr_maximum_visible_size state.current_workspace state
             in
             { state; workspace_reorg = Full; force_focus = None }
         | Column_count Decr ->
             let state =
               decr_maximum_visible_size state.current_workspace state
             in
             { state; workspace_reorg = Full; force_focus = None }
         | Set_status_bar_name name ->
             let state = { state with status_bar_name = Some name } in
             no_visible_update state
       in
       (res, { success = true })
   | Get_workspaces ->
       let focus, state =
         match int_of_string_opt state.current_workspace with
         | Some current -> (current, state)
         | None ->
             (* Forcing a valid workspace *)
             (* TODO: Force a jump to this workspace *)
             (0, { state with current_workspace = "0" })
       in
       let windows =
         Workspaces_registry.summary state.workspaces
         |> List.map (fun (k, w) ->
                (k, (Windows_registry.find w state.windows).window))
       in
       (no_visible_update state, { focus; windows })
   | Get_windows -> (
       let ribbon =
         Workspaces_registry.find_opt state.current_workspace state.workspaces
       in
       ( no_visible_update state,
         match ribbon with
         | None -> { focus = None; windows = [] }
         | Some ribbon -> (
             match Ribbon.windows_summary ribbon with
             | Some (f, l) ->
                 {
                   focus = Some f;
                   windows =
                     List.map
                       (fun id ->
                         (Windows_registry.find id state.windows).window)
                       l;
                 }
             | None -> { focus = None; windows = [] }) ))
   | Get_workspace_config ->
       ( no_visible_update state,
         match
           Workspaces_registry.find_opt state.current_workspace state.workspaces
         with
         | Some workspace ->
             {
               layout = Ribbon.layout workspace;
               column_count = Ribbon.column_count workspace;
             }
         | None ->
             {
               layout = default_layout state state.current_workspace;
               column_count = default_column_count state state.current_workspace;
             } )
    : update * a)

let pp fmt state =
  Format.(
    fprintf fmt "current_workspace: %s@ windows: %a@ workspaces: %a"
      state.current_workspace Windows_registry.pp state.windows
      Workspaces_registry.pp state.workspaces)

let load_config state =
  let ( // ) = Filename.concat in
  let config_dir =
    match Sys.getenv_opt "XDG_CONFIG_HOME" with
    | Some config_base -> config_base
    | None -> Sys.getenv "HOME" // ".config"
  in
  let config = Spatial_ipc.from_file (config_dir // "spatial" // "config") in
  List.fold_left
    (fun state cmd ->
      let { state; _ }, _ = client_command_handle state (Run_command cmd) in
      state)
    state
    (Option.value ~default:[] config)

let signal_status_bar state =
  match state.status_bar_name with
  | Some name ->
      ignore (Jobs.shell Format.(sprintf "/usr/bin/pkill -SIGRTMIN+8 %s" name))
  | None -> ()

let init () =
  let cw = Sway_ipc.get_current_workspace () in
  let tree = Sway_ipc.get_tree () in
  let workspaces = Node.filter (fun x -> x.node_type = Workspace) tree in
  List.fold_left
    (fun state workspace ->
      match workspace.Node.name with
      | Some workspace_name ->
          Node.fold state (register_window workspace_name) workspace
      | None -> state)
    (empty cw.name |> load_config)
    workspaces
