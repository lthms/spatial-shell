open Spatial_ipc

let () =
  Clap.description "A client to communicate with a Spatial instance.";

  let ty = Clap.default_string ~short:'t' ~last:true "run_command" in

  match ty with
  | "run_command" ->
      let cmd = Clap.mandatory_string ~placeholder:"CMD" () in
      Clap.close ();

      let cmd = command_of_string_exn cmd in
      let { success } = send_command (Run_command cmd) in
      if not success then exit 1
  | "get_windows" -> (
      let cmd = Clap.optional_int ~placeholder:"INDEX" () in
      Clap.close ();

      let reply = send_command Get_windows in

      match (cmd, reply.focus) with
      | Some idx, Some focus when idx < List.length reply.windows ->
          let name = List.nth reply.windows idx in
          let cls = if idx = focus then "focus" else "unfocus" in
          Format.(printf "%s\n%s\n%s" name name cls)
      | Some _, _ -> ()
      | None, _ ->
          List.iteri
            (fun idx name ->
              let marker = if reply.focus = Some idx then "*" else "" in
              Format.printf "| %s%s%s | " marker name marker)
            reply.windows)
  | _ -> exit 2
