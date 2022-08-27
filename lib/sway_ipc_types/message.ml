type subscribe_reply = { success : bool }

let subscribe_reply_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ success = field "success" bool in
  { success }

type run_command_reply = {
  success : bool;
  parse_error : bool option;
  error : string option;
}

let run_command_reply_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ success = field "success" bool
  and+ parse_error = field_opt "parse_error" bool
  and+ error = field_opt "error" string in
  { success; parse_error; error }

type _ t =
  | Run_command : Command.t list -> run_command_reply list t
  | Get_workspaces : Workspace.t list t
  | Subscribe : Event.event_type list -> subscribe_reply t
  | Get_tree : Node.t t
  | Get_outputs : Output.t list t

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

let reply_decoder : type reply. reply t -> reply Json_decoder.t = function
  | Run_command _ -> Json_decoder.list run_command_reply_decoder
  | Get_workspaces -> Json_decoder.list Workspace.decoder
  | Subscribe _ -> subscribe_reply_decoder
  | Get_outputs -> Json_decoder.list Output.decoder
  | Get_tree -> Node.decoder
