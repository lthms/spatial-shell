open Sway_ipc_types

type input = From_sway of Event.t | From_client of Spatial_ipc.socket

let workspace_handle (ev : Event.workspace_event) state =
  match ev.change with
  | Focus ->
      let state =
        match ev.current.name with
        | Some workspace -> State.set_current_workspace workspace state
        | None -> state
      in
      Lwt.return (state, true, None)
  | Init | Empty | Move | Rename | Urgent | Reload ->
      Lwt.return (state, false, None)

let window_handle (ev : Event.window_event) state =
  match ev.change with
  | Event.New ->
      let state =
        State.register_window false 2 state.State.current_workspace state
          ev.container
      in
      Lwt.return (state, true, None)
  | Event.Close ->
      let state = State.unregister_window state ev.container.id in
      Lwt.return (state, true, None)
  | Event.Focus | Event.Title | Event.Fullscreen_mode | Event.Move | Event.Mark
  | Event.Urgent ->
      Lwt.return (state, false, None)
  | Event.Floating -> (
      match ev.container.node_type with
      | Con ->
          let state =
            State.register_window false 2 state.State.current_workspace state
              ev.container
          in
          Lwt.return (state, true, None)
      | Floating_con ->
          let state = State.unregister_window state ev.container.id in
          Lwt.return (state, true, Some ev.container.id)
      | _ -> Lwt.return (state, false, None))

let event_handle ev state =
  let open Lwt.Syntax in
  Lwt.try_bind
    (fun () ->
      let* state, arrange, force_focus =
        match ev with
        | From_sway (Event.Workspace ev) -> workspace_handle ev state
        | From_sway (Window ev) -> window_handle ev state
        | From_sway _ -> assert false
        | From_client socket -> (
            let+ handle_res =
              Spatial_ipc.(
                handle_next_command ~socket state
                  { handler = State.client_command_handle })
            in
            match handle_res with Some x -> x | _ -> (state, false, None))
      in
      let+ () =
        if arrange then State.arrange_current_workspace ?force_focus state
        else Lwt.return ()
      in
      state)
    Lwt.return
    (fun _exn ->
      let+ _ = Lwt_io.printf "something went wrong with an event\n" in
      state)

let merge_streams l =
  let open Lwt.Syntax in
  Lwt_stream.from (fun () ->
      Lwt.choose
        (List.map
           (fun x ->
             let+ x = Lwt_stream.next x in
             Some x)
           l))

let main () =
  let open Lwt.Syntax in
  let* stream_sway = Sway_ipc.subscribe [ Window; Workspace ] in
  let* stream_client = Spatial_ipc.create_server () in
  let stream =
    merge_streams
      [
        Lwt_stream.map (fun x -> From_sway x) stream_sway;
        Lwt_stream.map (fun x -> From_client x) stream_client;
      ]
  in
  let* state = State.init false 2 in
  let* () = State.arrange_current_workspace state in
  let string = Format.asprintf "%a" State.pp state in
  let* () = Lwt_io.printf "%s\n" string in
  let* _ = Lwt_stream.fold_s event_handle stream state in
  Lwt.return ()

let () = Lwt_main.run @@ main ()
