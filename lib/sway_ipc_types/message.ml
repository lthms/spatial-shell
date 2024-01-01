(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type subscribe_reply = { success : bool }

let subscribe_reply_decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ success = field "success" bool in
  { success }

type run_command_reply = {
  success : bool;
  parse_error : bool option;
  error : string option;
}

let run_command_reply_decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ success = field "success" bool
  and+ parse_error = field_opt "parse_error" bool
  and+ error = field_opt "error" string in
  { success; parse_error; error }

type send_tick_reply = { success : bool }

let send_tick_reply_decoder =
  let open Ezjsonm_encoding.Decoding in
  let open Syntax in
  let+ success = field "success" bool in
  { success }

type _ t =
  | Run_command : Command.t list -> run_command_reply list t
  | Get_workspaces : Workspace.t list t
  | Subscribe : Event.event_type list -> subscribe_reply t
  | Get_tree : Node.t t
  | Get_outputs : Output.t list t
  | Send_tick : string -> send_tick_reply t

let to_raw_message : type reply. reply t -> Mltp_ipc.Raw_message.t = function
  | Run_command cmds ->
      ( 0l,
        Format.(
          asprintf "%a"
            (pp_print_list
               ~pp_sep:(fun fmt () -> pp_print_string fmt "\n")
               (fun fmt x -> fprintf fmt "%a" Command.pp x))
            cmds) )
  | Get_workspaces -> (1l, "")
  | Subscribe evs ->
      ( 2l,
        Format.(
          asprintf "[%a]"
            (pp_print_list
               ~pp_sep:(fun fmt () -> pp_print_string fmt ", ")
               (fun fmt x -> fprintf fmt "\"%s\"" (Event.event_type_string x)))
            evs) )
  | Get_outputs -> (3l, "")
  | Get_tree -> (4l, "")
  | Send_tick payload -> (10l, payload)

let reply_decoder : type reply. reply t -> reply Ezjsonm_encoding.Decoding.t =
  function
  | Run_command _ -> Ezjsonm_encoding.Decoding.list run_command_reply_decoder
  | Get_workspaces -> Ezjsonm_encoding.Decoding.list Workspace.decoder
  | Subscribe _ -> subscribe_reply_decoder
  | Get_outputs -> Ezjsonm_encoding.Decoding.list Output.decoder
  | Get_tree -> Node.decoder
  | Send_tick _ -> send_tick_reply_decoder
