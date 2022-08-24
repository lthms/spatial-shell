let select_message = function
  | `Focus `Prev -> Spatial_sway_ipc.Move_left
  | `Focus `Next -> Move_right
  | `Move `Prev -> Move_window_left
  | `Move `Next -> Move_window_right
  | `Maximize `Toggle -> Toggle_full_view
  | `Split `Incr -> Incr_maximum_visible_space
  | `Split `Decr -> Decr_maximum_visible_space

let connect () =
  let open Lwt.Syntax in
  let socket = Lwt_unix.socket PF_UNIX SOCK_STREAM 0 in
  let+ () = Lwt_unix.connect socket (ADDR_UNIX Spatial_sway_ipc.socket_path) in
  socket

let send_command socket cmd =
  let open Lwt.Syntax in
  let buffer = Bytes.create 4 in
  Bytes.set_int32_ne buffer 0 (Spatial_sway_ipc.to_int32 cmd);
  let* _ = Lwt_unix.write socket buffer 0 4 in
  Lwt.return ()

let main cmd =
  let open Lwt.Syntax in
  let* socket = connect () in
  let* () = send_command socket cmd in
  Lwt_unix.close socket

let () =
  Clap.description
    "Send messages to a running instance of spatial-sway over the IPC socket";

  let command =
    Clap.subcommand
      [
        ( Clap.case "focus" ~description:"Change the focused window."
        @@ fun () ->
          let direction =
            Clap.subcommand ~placeholder:"DIRECTION"
              [
                Clap.case "prev"
                  ~description:"Focus the previous window in the ribbon."
                  (fun () -> `Prev);
                Clap.case "next"
                  ~description:"Focus the next window in the ribbon." (fun () ->
                    `Next);
              ]
          in
          `Focus direction );
        ( Clap.case "move" ~description:"Move the focused window." @@ fun () ->
          let direction =
            Clap.subcommand ~placeholder:"DIRECTION"
              [
                Clap.case "prev"
                  ~description:
                    "Move the focused container before the previous window in \
                     the ribbon." (fun () -> `Prev);
                Clap.case "next"
                  ~description:
                    "Move the focused container after the previous window in \
                     the ribbon." (fun () -> `Next);
              ]
          in
          `Move direction );
        ( Clap.case "maximize" ~description:"Enable or disable maximized mode."
        @@ fun () ->
          let switch =
            Clap.subcommand ~placeholder:"SWITCH"
              [
                Clap.case "toggle" ~description:"Toggle the maximized mode"
                  (fun () -> `Toggle);
              ]
          in
          `Maximize switch );
        ( Clap.case "split" ~description:"Configure the split mode." @@ fun () ->
          let cmd =
            Clap.subcommand ~placeholder:"COMMAND"
              [
                Clap.case "increment"
                  ~description:"Push one more window onto the output."
                  (fun () -> `Incr);
                Clap.case "decrement"
                  ~description:"Remove one window from the output." (fun () ->
                    `Decr);
              ]
          in
          `Split cmd );
      ]
  in

  let cmd = select_message command in

  Lwt_main.run (main cmd)
