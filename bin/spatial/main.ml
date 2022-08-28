open Sway_ipc_types

let workspace_handle (ev : Event.workspace_event) state =
  match ev.change with
  | Focus ->
      let state =
        match ev.current.name with
        | Some workspace -> State.set_current_workspace workspace state
        | None -> state
      in
      (state, true, None)
  | Init | Empty | Move | Rename | Urgent | Reload -> (state, false, None)

let window_handle (ev : Event.window_event) state =
  match ev.change with
  | Event.New ->
      let state =
        State.register_window false 2 state.State.current_workspace state
          ev.container
      in
      (state, true, None)
  | Event.Close ->
      let state = State.unregister_window state ev.container.id in
      (state, true, None)
  | Event.Focus | Event.Title | Event.Fullscreen_mode | Event.Move | Event.Mark
  | Event.Urgent ->
      (state, false, None)
  | Event.Floating -> (
      match ev.container.node_type with
      | Con ->
          let state =
            State.register_window false 2 state.State.current_workspace state
              ev.container
          in
          (state, true, None)
      | Floating_con ->
          let state = State.unregister_window state ev.container.id in
          (state, true, Some ev.container.id)
      | _ -> (state, false, None))

let with_nonblock_socket socket f =
  Unix.clear_nonblock socket;
  let res = f () in
  Unix.set_nonblock socket;
  res

let rec go poll state sway_socket server_socket =
  try
    match Poll.wait poll (Poll.Timeout.after 10_000_000_000_000L) with
    | `Timeout -> go poll state sway_socket server_socket
    | `Ok ->
        let ref_state = ref state in
        let ref_arrange = ref false in
        let ref_force_focus = ref None in
        Poll.iter_ready poll ~f:(fun fd _event ->
            try
              let state, arrange, force_focus =
                if fd = sway_socket then
                  with_nonblock_socket fd @@ fun () ->
                  match Sway_ipc.read_event fd with
                  | Workspace ev -> workspace_handle ev !ref_state
                  | Window ev -> window_handle ev !ref_state
                  | _ -> assert false
                else if fd = server_socket then (
                  let client = Spatial_ipc.accept fd in
                  Unix.set_nonblock client;
                  Poll.(set poll client Event.read);
                  (!ref_state, false, None))
                else
                  with_nonblock_socket fd @@ fun () ->
                  match
                    Spatial_ipc.handle_next_command ~socket:fd !ref_state
                      { handler = State.client_command_handle }
                  with
                  | Some res -> res
                  | None -> (!ref_state, false, None)
              in
              Poll.(set poll fd Event.read);
              ref_arrange := arrange || !ref_arrange;
              ref_state := state;
              ref_force_focus := force_focus
            with
            | Mltp_ipc.Socket.Connection_closed
            when fd <> sway_socket && fd <> server_socket
            ->
              Unix.set_nonblock fd;
              Poll.(set poll fd Event.none);
              Unix.close fd);
        if !ref_arrange then (
          State.arrange_current_workspace ?force_focus:!ref_force_focus
            !ref_state;
          (* TODO: Be more configurable about that *)
          ignore (Unix.system "/usr/bin/pkill -SIGRTMIN+8 waybar"));
        Poll.clear poll;
        go poll !ref_state sway_socket server_socket
  with Unix.Unix_error (EINTR, _, _) ->
    go poll state sway_socket server_socket

let () =
  Printexc.record_backtrace true;
  let poll = Poll.create () in

  let sway_socket = Sway_ipc.subscribe [ Window; Workspace ] in
  Unix.set_nonblock sway_socket;
  Poll.(set poll sway_socket Event.read);

  let server_socket = Spatial_ipc.create_server () in
  Unix.set_nonblock server_socket;
  Poll.(set poll server_socket Event.read);

  let state = State.init false 2 in
  State.arrange_current_workspace state;

  go poll state sway_socket server_socket
