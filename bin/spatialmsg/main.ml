(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Spatial_ipc

type format = Json | Quiet

let pp_json encoding fmt value =
  let json = Data_encoding.Json.construct encoding value in
  Format.fprintf fmt "%s" Data_encoding.Json.(to_string json)

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

let format_clap () =
  Clap.(
    flag_enum
      ~section:
        (section "FORMAT"
           ~description:
             "Specify the format spatialmsg will use to output the result of \
              the RPC command.")
      [ ([ "json" ], [], Json); ([ "quiet" ], [], Quiet) ]
      Json)

let clap_close =
  Clap.close
    ~on_help:(fun () -> ())
    ~on_error:(fun msg ->
      Format.(fprintf err_formatter "Error: %s@ " msg);
      exit 1)

let exec format = function
  | "run_command" ->
      let cmd = Clap.mandatory_string ~placeholder:"CMD" () in
      clap_close ();
      let cmd = command_of_string_exn cmd in
      let reply = send_command (Run_command cmd) in
      output_run_command reply format;
      if not reply.success then exit 1
  | "get_windows" ->
      clap_close ();
      let reply = send_command Get_windows in
      output_get_windows reply format
  | "get_workspaces" ->
      clap_close ();
      let reply = send_command Get_workspaces in
      output_get_workspaces reply format
  | "get_workspace_config" ->
      let reply = send_command Get_workspace_config in
      clap_close ();
      output_get_workspace_config reply format
  | _ ->
      clap_close ();
      exit 2

let () =
  Clap.description "A client to communicate with a Spatial instance.";

  let format = format_clap () in

  let ty =
    Clap.default_string ~long:"type" ~short:'t' ~last:true "run_command"
      ~description:"Specify the type of IPC message."
  in

  exec format ty
