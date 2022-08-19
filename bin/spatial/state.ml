open Sway_ipc_types

type state = {
  current_workspace : string;
  windows : Windows_registry.t;
  workspaces : Workspaces_registry.t;
}

let empty current_workspace =
  {
    current_workspace;
    windows = Windows_registry.empty;
    workspaces = Workspaces_registry.empty;
  }

let set_current_workspace current_workspace state =
  { state with current_workspace }

let insert_window default_full_view default_maximum_visible workspace window
    app_id state =
  {
    state with
    workspaces =
      Workspaces_registry.register_window default_full_view
        default_maximum_visible workspace window state.workspaces;
    windows =
      Windows_registry.register window { app_id; workspace } state.windows;
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

let arrange_workspace_commands ~focus workspace state =
  match Workspaces_registry.find_opt workspace state.workspaces with
  | Some ribbon -> Ribbon.arrange_commands ~focus workspace ribbon
  | None -> []

let arrange_workspace ~focus ~socket workspace state =
  let open Lwt.Syntax in
  let cmds = arrange_workspace_commands ~focus workspace state in
  let* _replies = Sway_ipc.send_command ~socket (Run_command cmds) in
  Lwt.return ()

let arrange_current_workspace state =
  Sway_ipc.wtih_socket (fun socket ->
      arrange_workspace ~focus:true ~socket state.current_workspace state)

let register_window default_full_view default_maximum_visible workspace state
    (tree : Node.t) =
  match tree.app_id with
  | Some app_id ->
      insert_window default_full_view default_maximum_visible workspace tree.id
        app_id state
  | _ -> state

let unregister_window state window =
  let info = Windows_registry.find window state.windows in
  let windows = Windows_registry.unregister window state.windows in
  let workspaces =
    Workspaces_registry.update info.workspace
      (function
        | Some ribbon -> Some (Ribbon.remove_window window ribbon)
        | None -> None)
      state.workspaces
  in
  { state with windows; workspaces }

let init default_full_view default_maximum_visible =
  let open Lwt.Syntax in
  let* cw = Sway_ipc.get_current_workspace () in
  let+ tree = Sway_ipc.get_tree () in
  let workspaces = Node.filter (fun x -> x.node_type = Workspace) tree in
  List.fold_left
    (fun state workspace ->
      match workspace.Node.name with
      | Some workspace_name ->
          Node.fold state
            (register_window default_full_view default_maximum_visible
               workspace_name)
            workspace
      | None -> state)
    (empty cw.name) workspaces

let client_handle ev state =
  Lwt.return
  @@
  match ev with
  | Spatial_sway_ipc.Move_left ->
      ( {
          state with
          workspaces =
            Workspaces_registry.update state.current_workspace
              (function
                | Some ribbon -> Some (Ribbon.move_focus_left ribbon)
                | None -> None)
              state.workspaces;
        },
        true )
  | Move_right ->
      ( {
          state with
          workspaces =
            Workspaces_registry.update state.current_workspace
              (function
                | Some ribbon -> Some (Ribbon.move_focus_right ribbon)
                | None -> None)
              state.workspaces;
        },
        true )
  | Move_window_left -> (move_window_left state.current_workspace state, true)
  | Move_window_right -> (move_window_right state.current_workspace state, true)
  | Toggle_full_view -> (toggle_full_view state.current_workspace state, true)
  | Incr_maximum_visible_space ->
      (incr_maximum_visible_size state.current_workspace state, true)
  | Decr_maximum_visible_space ->
      (decr_maximum_visible_size state.current_workspace state, true)

let pp fmt state =
  Format.(
    fprintf fmt "current_workspace: %s@ windows: %a@ workspaces: %a"
      state.current_workspace Windows_registry.pp state.windows
      Workspaces_registry.pp state.workspaces)
