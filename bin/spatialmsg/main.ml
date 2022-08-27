open Spatial_ipc

let () =
  Clap.description "A client to communicate with a Spatial instance.";

  let ty = Clap.default_string ~short:'t' ~last:true "run_command" in

  match ty with
  | "run_command" ->
      let cmd = Clap.mandatory_string ~placeholder:"CMD" () in
      Clap.close ();

      let cmd = command_of_string_exn cmd in
      let { success } = Lwt_main.run (send_command (Run_command cmd)) in
      if not success then exit 1
  | "get_windows" ->
      Clap.close ();

      let reply = Lwt_main.run (send_command Get_windows) in
      List.iteri
        (fun idx name ->
          Format.printf "- %s%s%s\n"
            (if reply.focus = Some idx then "*" else "")
            name
            (if reply.focus = Some idx then "*" else ""))
        reply.windows
  | _ -> exit 2
