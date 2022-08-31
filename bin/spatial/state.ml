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

let arrange_workspace_commands ?force_focus workspace state =
  match Workspaces_registry.find_opt workspace state.workspaces with
  | Some ribbon -> Ribbon.arrange_commands ?force_focus workspace ribbon
  | None -> []

let arrange_workspace ?force_focus ~socket workspace state =
  let cmds = arrange_workspace_commands ?force_focus workspace state in
  let _replies = Sway_ipc.send_command ~socket (Run_command cmds) in
  ()

let arrange_current_workspace ?force_focus state =
  Sway_ipc.with_socket (fun socket ->
      arrange_workspace ?force_focus ~socket state.current_workspace state)

let register_window default_full_view default_maximum_visible workspace state
    (tree : Node.t) =
  match (tree.node_type, tree.app_id) with
  | Con, Some app_id ->
      insert_window default_full_view default_maximum_visible workspace tree.id
        app_id state
  | _ -> state

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

let init default_full_view default_maximum_visible =
  let cw = Sway_ipc.get_current_workspace () in
  let tree = Sway_ipc.get_tree () in
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

(* TODO: Make it configurable *)
let max_workspace = 6

let send_command_workspace : 'kind Spatial_ipc.target -> state -> unit =
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
         | Move Prev ->
             (move_window_left state.current_workspace state, true, None)
         | Move Next ->
             (move_window_right state.current_workspace state, true, None)
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
         |> List.map (fun (k, w) ->
                (k, (Windows_registry.find w state.windows).app_id))
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
             | Some (f, l) ->
                 {
                   focus = Some f;
                   windows =
                     List.map
                       (fun id ->
                         (Windows_registry.find id state.windows).app_id)
                       (l @ ribbon.hidden);
                 }
             | None -> { focus = None; windows = [] }) ))
    : _ * a)

let pp fmt state =
  Format.(
    fprintf fmt "current_workspace: %s@ windows: %a@ workspaces: %a"
      state.current_workspace Windows_registry.pp state.windows
      Workspaces_registry.pp state.workspaces)
