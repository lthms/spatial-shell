(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Sway_ipc_types

exception Sway_exited

external reraise : exn -> 'a = "%reraise"

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
        State.register_window state.State.current_workspace state ev.container
      in
      (state, true, None)
  | Event.Close ->
      let state = State.unregister_window state ev.container.id in
      (state, true, None)
  | Event.Title ->
      let state = State.record_window_title_change state ev.container in
      (state, false, None)
  | Event.Focus | Event.Fullscreen_mode | Event.Move | Event.Mark | Event.Urgent
    ->
      (state, false, None)
  | Event.Floating -> (
      match ev.container.node_type with
      | Con ->
          let state =
            State.register_window state.State.current_workspace state
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

let poll_fold_ready poll acc f =
  let ref_acc = ref acc in
  Poll.iter_ready poll ~f:(fun fd event -> ref_acc := f !ref_acc fd event);
  !ref_acc

let rec go poll state sway_socket server_socket =
  try
    match Poll.wait poll (Poll.Timeout.after 10_000_000_000_000L) with
    | `Timeout -> go poll state sway_socket server_socket
    | `Ok ->
        let previous_state = state in
        let state, arrange, force_focus =
          poll_fold_ready poll (state, false, None)
            (fun (state, arrange, force_focus) fd _event ->
              try
                let res =
                  if fd = sway_socket then
                    with_nonblock_socket fd @@ fun () ->
                    match Sway_ipc.read_event fd with
                    | Workspace ev -> workspace_handle ev state
                    | Window ev -> window_handle ev state
                    | _ -> assert false
                  else if fd = server_socket then (
                    let client = Spatial_ipc.accept fd in
                    Unix.set_nonblock client;
                    Poll.(set poll client Event.read);
                    (state, arrange, force_focus))
                  else
                    with_nonblock_socket fd @@ fun () ->
                    match
                      Spatial_ipc.handle_next_command ~socket:fd state
                        { handler = State.client_command_handle }
                    with
                    | Some res -> res
                    | None -> (state, arrange, force_focus)
                in
                Poll.(set poll fd Event.read);
                res
              with
              | Mltp_ipc.Socket.Connection_closed when fd = sway_socket ->
                  raise Sway_exited
              | Mltp_ipc.Socket.Connection_closed when fd <> server_socket ->
                  Poll.(set poll fd Event.none);
                  Unix.close fd;
                  (state, arrange, force_focus))
        in
        let state =
          if arrange then (
            (* TODO: Be more configurable about that *)
            ignore (Jobs.shell "/usr/bin/pkill -SIGRTMIN+8 waybar");
            State.arrange_current_workspace ~previous_state ?force_focus state;
            State.handle_background state)
          else state
        in
        Poll.clear poll;
        go poll state sway_socket server_socket
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

  let state = State.(init () |> handle_background) in
  State.arrange_current_workspace state;

  try go poll state sway_socket server_socket with
  | Sway_exited -> ()
  | exn -> reraise exn
