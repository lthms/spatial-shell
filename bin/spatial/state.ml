open Sway_ipc_types
module Workspaces_map = Stdlib.Map.Make (String)

type state = {
  current_workspace : string;
  windows : Windows_registry.t;
  workspaces : Workspaces_registry.t;
  default_focus_view : bool;
  focus_view_per_workspace : bool Workspaces_map.t;
  default_visible_windows : int;
  visible_windows_per_workspace : int Workspaces_map.t;
}

let empty current_workspace =
  {
    current_workspace;
    windows = Windows_registry.empty;
    workspaces = Workspaces_registry.empty;
    default_focus_view = false;
    focus_view_per_workspace = Workspaces_map.empty;
    default_visible_windows = 2;
    visible_windows_per_workspace = Workspaces_map.empty;
  }

let default_focus_view { default_focus_view; focus_view_per_workspace; _ }
    workspace =
  match Workspaces_map.find_opt workspace focus_view_per_workspace with
  | Some x -> x
  | None -> default_focus_view

let default_visible_windows
    { default_visible_windows; visible_windows_per_workspace; _ } workspace =
  match Workspaces_map.find_opt workspace visible_windows_per_workspace with
  | Some x -> x
  | None -> default_visible_windows

let internal_register_window state target_workspace window =
  Workspaces_registry.register_window
    (default_focus_view state target_workspace)
    (default_visible_windows state target_workspace)
    target_workspace window

let set_current_workspace current_workspace state =
  { state with current_workspace }

let focus_index workspace state index =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.focus_index ribbon index) | None -> None)
        state.workspaces;
  }

let toggle_full_view workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.toggle_full_view ribbon) | None -> None)
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
          match ribbon.visible with
          | Some (f, l) ->
              let window = List.nth l f in
              let ribbon = Ribbon.remove_window window ribbon in
              {
                state with
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
      | Some x when 0 < x -> Some (string_of_int (x - 1))
      | _ -> None)

let move_window_down =
  move_window_in_workspace (fun current ->
      match int_of_string_opt current with
      (* TODO: 6 should be configurable *)
      | Some x when x < 6 -> Some (string_of_int (x + 1))
      | _ -> None)

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
          | None -> None)
        state.workspaces;
  }

let decr_maximum_visible_size workspace state =
  {
    state with
    workspaces =
      Workspaces_registry.update workspace
        (function
          | Some ribbon -> Some (Ribbon.decr_maximum_visible ribbon)
          | None -> None)
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
  let _replies = Sway_ipc.send_command ~socket (Run_command cmds) in
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
          Windows_registry.register id { app_id; workspace; name } state.windows;
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
                {
                  info with
                  Spatial_ipc.name = Option.value ~default:"" node.name;
                }
          | None -> None)
        state.windows;
  }

let unregister_window state window =
  match Windows_registry.find_opt window state.windows with
  | Some info ->
      let windows = Windows_registry.unregister window state.windows in
      let workspaces =
        Workspaces_registry.update info.workspace
          (function
            | Some ribbon -> Some (Ribbon.remove_window window ribbon)
            | None -> None)
          state.workspaces
      in
      { state with windows; workspaces }
  | None -> state

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
    (empty cw.name) workspaces

(* TODO: Make it configurable *)
let max_workspace = 6

let send_command_workspace : Spatial_ipc.target -> state -> unit =
 fun dir state ->
  (match (dir, int_of_string_opt state.current_workspace) with
  | Next, Some x when x < max_workspace -> Some (x + 1)
  | Prev, Some x when 1 < x -> Some (x - 1)
  | (Next | Prev), Some _ -> None
  | (Next | Prev), None -> Some 0
  | Index t, _ -> Some t)
  |> function
  | Some target ->
      ignore
      @@ Sway_ipc.send_command
           (Run_command [ Workspace (string_of_int target) ])
  | None -> ()

let client_command_handle :
    type a. state -> a Spatial_ipc.t -> (state * bool * int64 option) * a =
 fun state cmd ->
  let open Spatial_ipc in
  (match cmd with
   | Run_command cmd ->
       let res =
         match cmd with
         | Default
             ({ workspace = None; builtin = Focus_view }, default_focus_view) ->
             ({ state with default_focus_view }, false, None)
         | Default ({ workspace = Some ws; builtin = Focus_view }, focus_view)
           ->
             ( {
                 state with
                 focus_view_per_workspace =
                   Workspaces_map.add (string_of_int ws) focus_view
                     state.focus_view_per_workspace;
               },
               false,
               None )
         | Default
             ( { workspace = None; builtin = Visible_windows },
               default_visible_windows ) ->
             ({ state with default_visible_windows }, false, None)
         | Default
             ( { workspace = Some ws; builtin = Visible_windows },
               visible_windows ) ->
             ( {
                 state with
                 visible_windows_per_workspace =
                   Workspaces_map.add (string_of_int ws) visible_windows
                     state.visible_windows_per_workspace;
               },
               false,
               None )
         | Focus Prev ->
             ( {
                 state with
                 workspaces =
                   Workspaces_registry.update state.current_workspace
                     (function
                       | Some ribbon -> Some (Ribbon.move_focus_left ribbon)
                       | None -> None)
                     state.workspaces;
               },
               true,
               None )
         | Focus Next ->
             ( {
                 state with
                 workspaces =
                   Workspaces_registry.update state.current_workspace
                     (function
                       | Some ribbon -> Some (Ribbon.move_focus_right ribbon)
                       | None -> None)
                     state.workspaces;
               },
               true,
               None )
         | Focus (Index x) ->
             (focus_index state.current_workspace state x, true, None)
         | Workspace dir ->
             (* Don’t update the state, but ask Sway to change the
                current workspace instead. This will trigger an event
                that we will eventually received. *)
             send_command_workspace dir state;
             (state, false, None)
         | Move Left ->
             (move_window_left state.current_workspace state, true, None)
         | Move Right ->
             (move_window_right state.current_workspace state, true, None)
         | Move Up -> (move_window_up state, true, None)
         | Move Down -> (move_window_down state, true, None)
         | Maximize Toggle ->
             (toggle_full_view state.current_workspace state, true, None)
         | Maximize _ ->
             (* TODO: implement [On] and [Off] cases *)
             (state, false, None)
         | Split Incr ->
             ( incr_maximum_visible_size state.current_workspace state,
               true,
               None )
         | Split Decr ->
             ( decr_maximum_visible_size state.current_workspace state,
               true,
               None )
       in
       (res, { success = true })
   | Get_workspaces ->
       let current, state =
         match int_of_string_opt state.current_workspace with
         | Some current -> (current, state)
         | None ->
             (* Forcing a valid workspace *)
             (* TODO: Force a jump to this workspace *)
             (0, { state with current_workspace = "0" })
       in
       let windows =
         Workspaces_registry.summary state.workspaces
         |> List.map (fun (k, w) -> (k, Windows_registry.find w state.windows))
       in
       ((state, false, None), { current; windows })
   | Get_windows -> (
       let ribbon =
         Workspaces_registry.find_opt state.current_workspace state.workspaces
       in
       ( (state, false, None),
         match ribbon with
         | None -> { focus = None; windows = [] }
         | Some ribbon -> (
             match ribbon.visible with
             | Some (f, _) ->
                 {
                   focus = Some (f + List.length ribbon.hidden_left);
                   windows =
                     List.map
                       (fun id -> Windows_registry.find id state.windows)
                       (Ribbon.all_windows ribbon);
                 }
             | None -> { focus = None; windows = [] }) ))
    : _ * a)

let pp fmt state =
  Format.(
    fprintf fmt "current_workspace: %s@ windows: %a@ workspaces: %a"
      state.current_workspace Windows_registry.pp state.windows
      Workspaces_registry.pp state.workspaces)
