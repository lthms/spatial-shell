(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Spatial_ipc

let default_icon = ""
let empty_workspace_icon = "◯"

(* TODO: This should be part of the config of spatial
   Something like 'for window [app_id="firefox"] icon ""'. *)
let icon_of info =
  match info.app_id with
  | "firefox" -> Some ""
  | "kitty" -> Some ""
  | "Slack" -> Some ""
  | "emacs" -> Some ""
  | _ -> None

type format = Waybar

let workspace_icon workspace windows =
  List.assq_opt workspace windows |> function
  | Some info -> Option.value ~default:default_icon (icon_of info)
  | None -> empty_workspace_icon

let output_get_windows reply index = function
  | Waybar -> (
      match (index, reply.focus) with
      | Some idx, Some focus when idx < List.length reply.windows ->
          let window = List.nth reply.windows idx in
          let name =
            Option.value
              ~default:(default_icon ^ " " ^ window.app_id)
              (icon_of window)
          in
          let cls = if idx = focus then "focus" else "unfocus" in
          Format.(printf "%s\n%s\n%s" name window.app_id cls)
      | Some _, _ -> ()
      | None, _ ->
          List.iteri
            (fun idx info ->
              let marker = if reply.focus = Some idx then "*" else "" in
              Format.printf "| %s%s%s | " marker info.app_id marker)
            reply.windows)

let output_get_workspaces reply index = function
  | Waybar -> (
      match index with
      | Some i ->
          let cls = if i = reply.current then "focus" else "unfocused" in
          Format.(
            printf "%s\n%s\n%s"
              (workspace_icon i reply.windows)
              (string_of_int i) cls)
      | None ->
          Format.(
            printf "%a@?"
              (pp_print_list
                 ~pp_sep:(fun fmt () -> pp_print_string fmt "  ")
                 (fun fmt k ->
                   Format.fprintf fmt "%d:%s" k (workspace_icon k reply.windows)))
              (List.init 6 (fun x -> x + 1))))

let output_get_workspace_config reply = function
  | Waybar ->
      Format.(
        printf "%s  %d"
          (if reply.layout = Maximize then "" else "")
          reply.column_count)

let format_clap () =
  Clap.(
    flag_enum
      ~section:
        (section "FORMAT"
           ~description:
             "Specify the format spatialmsg will use to output the result of \
              the RPC command.")
      [ ([ "waybar" ], [], Waybar) ]
      Waybar)

let () =
  Clap.description "A client to communicate with a Spatial instance.";

  let format = format_clap () in

  let ty =
    Clap.default_string ~long:"type" ~short:'t' ~last:true "run_command"
      ~description:"Specify the type of IPC message."
  in

  match ty with
  | "run_command" ->
      let cmd = Clap.mandatory_string ~placeholder:"CMD" () in
      Clap.close ();
      let cmd = command_of_string_exn cmd in
      let { success } = send_command (Run_command cmd) in
      if not success then exit 1
  | "get_windows" ->
      let cmd = Clap.optional_int ~placeholder:"INDEX" () in
      Clap.close ();
      let reply = send_command Get_windows in
      output_get_windows reply cmd format
  | "get_workspaces" ->
      let cmd = Clap.optional_int ~placeholder:"INDEX" () in
      Clap.close ();
      let reply = send_command Get_workspaces in
      output_get_workspaces reply cmd format
  | "get_workspace_config" ->
      let reply = send_command Get_workspace_config in
      Clap.close ();
      output_get_workspace_config reply format
  | _ ->
      Clap.close ();
      exit 2
