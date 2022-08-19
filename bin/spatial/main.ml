open Sway_ipc_types

type input = From_sway of Event.t | From_client of Spatial_sway_ipc.t

let workspace_handle (ev : Event.workspace_event) state =
  match ev.change with
  | Focus ->
      let state =
        match ev.current.name with
        | Some workspace -> State.set_current_workspace workspace state
        | None -> state
      in
      Lwt.return (state, true)
  | Init | Empty | Move | Rename | Urgent | Reload -> Lwt.return (state, false)

let window_handle (ev : Event.window_event) state =
  match ev.change with
  | Event.New ->
      let state =
        State.register_window false 2 state.State.current_workspace state
          ev.container
      in
      Lwt.return (state, true)
  | Event.Close ->
      let state = State.unregister_window state ev.container.id in
      Lwt.return (state, true)
  | Event.Focus | Event.Title | Event.Fullscreen_mode | Event.Move | Event.Mark
  | Event.Urgent ->
      Lwt.return (state, false)
  | Event.Floating ->
      (* TODO: disable spatial-sway for the concerned workspace *)
      Lwt.return (state, false)

let event_handle ev state =
  let open Lwt.Syntax in
  Lwt.try_bind
    (fun () ->
      let* state, arrange =
        match ev with
        | From_sway (Event.Workspace ev) -> workspace_handle ev state
        | From_sway (Window ev) -> window_handle ev state
        | From_client ev -> State.client_handle ev state
        | _ -> assert false
      in
      let+ () =
        if arrange then State.arrange_current_workspace state else Lwt.return ()
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
  let* stream_client = Ipc.create_server () in
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
