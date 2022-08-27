open Spatial_ipc

let () =
  let cmd = Sys.argv.(1) |> command_of_string_exn in
  Lwt_main.run (send_command (Run_command cmd))
