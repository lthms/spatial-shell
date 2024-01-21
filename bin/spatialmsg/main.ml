(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Spatial_ipc
open Cmdliner

let cli_error = 1
let spatial_error = 2

type format = Json | Quiet

let pp_json encoding fmt value =
  let json = Ezjsonm_encoding.to_string_exn ~minify:true encoding value in
  Format.fprintf fmt "%s" json

let output_get_windows (reply : Spatial_ipc.get_windows_reply) = function
  | Json ->
      Format.printf "%a" (pp_json Spatial_ipc.get_windows_reply_encoding) reply
  | Quiet -> ()

let output_get_workspaces reply = function
  | Json ->
      Format.printf "%a"
        (pp_json Spatial_ipc.get_workspaces_reply_encoding)
        reply
  | Quiet -> ()

let output_get_workspace_config reply = function
  | Json ->
      Format.printf "%a"
        (pp_json Spatial_ipc.get_workspace_config_reply_encoding)
        reply
  | Quiet -> ()

let output_run_command reply = function
  | Json ->
      Format.printf "%a" (pp_json Spatial_ipc.run_command_reply_encoding) reply
  | Quiet -> ()

let exec format ty cmd =
  match ty with
  | "run_command" -> (
      match command_of_string cmd with
      | Some cmd ->
          let reply = send_command (Run_command cmd) in
          output_run_command reply format;
          if not reply.success then exit spatial_error
      | None -> exit cli_error)
  | "get_windows" ->
      let reply = send_command Get_windows in
      output_get_windows reply format
  | "get_workspaces" ->
      let reply = send_command Get_workspaces in
      output_get_workspaces reply format
  | "get_workspace_config" ->
      let reply = send_command Get_workspace_config in
      output_get_workspace_config reply format
  | _ -> exit cli_error

let ty =
  Arg.(
    value & opt string "run_command"
    & info [ "t"; "type" ] ~docv:"type"
        ~doc:"Specify the type of the IPC message.")

let json =
  Arg.(
    info [ "json" ]
      ~doc:
        "Prints the response from Spatial Shell as received, that is in JSON.")

let quiet =
  Arg.(
    info [ "quiet" ]
      ~doc:
        "Sends the IPC message, but does not print the response from Spatial \
         Shell.")

let format = Arg.(value & vflag Json [ (Json, json); (Quiet, quiet) ])
let cmd = Arg.(value & pos 0 string "" & info [] ~docv:"message")
let spatialmsg_t = Term.(const exec $ format $ ty $ cmd)

let spatialmsg =
  let info = Cmd.info "spatialmsg" ~version:"6" in
  Cmd.v info spatialmsg_t

let () = exit (Cmd.eval spatialmsg)
