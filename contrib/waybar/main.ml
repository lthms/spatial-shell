open Spatial_ipc
module App_id_map = Hashtbl.Make (String)

let app_id_map = App_id_map.create 10

let entry_jsoner =
  let open Jsoner.Decoding in
  let open Syntax in
  let+ app_id = field "app_id" string and+ icon = field "icon" string in
  (app_id, icon)

let config_jsoner = Jsoner.Decoding.list entry_jsoner

let load_config () =
  let read_file path = In_channel.(with_open_text path input_all) in
  let ( // ) = Filename.concat in
  let config_dir =
    match Sys.getenv_opt "XDG_CONFIG_HOME" with
    | Some config_base -> config_base
    | None -> Sys.getenv "HOME" // ".config"
  in
  let config_path = config_dir // "spatial" // "spatialbar.json" in
  if Sys.file_exists config_path then
    let conf =
      read_file config_path |> Jsoner.Decoding.of_string_exn config_jsoner
    in
    List.iter (fun (entry, icon) -> App_id_map.add app_id_map entry icon) conf
  else ()

let icon_of_window window =
  Option.value ~default:"" @@ App_id_map.find_opt app_id_map window.app_id

let icon_of_workspace = function
  | None -> "◯"
  | Some window -> icon_of_window window

let () =
  load_config ();

  match Sys.argv.(1) with
  | "config" ->
      let reply = send_command Get_workspace_config in
      Format.printf "%s" (if reply.layout = Maximize then "" else "")
  | "workspace" ->
      let workspace_index = int_of_string Sys.argv.(2) in
      let reply = send_command Get_workspaces in
      let window_opt = List.assoc_opt workspace_index reply.windows in
      let is_focus =
        if workspace_index = reply.focus then "focus" else "unfocus"
      in
      Format.printf "%s\n%d\n%s"
        (icon_of_workspace window_opt)
        workspace_index is_focus
  | "window" -> (
      let window_index = int_of_string Sys.argv.(2) in
      let reply = send_command Get_windows in
      match List.nth_opt reply.windows window_index with
      | Some window ->
          let is_focus =
            if reply.focus = Some window_index then "focus" else "unfocus"
          in
          Format.printf "%s\n%s\n%s" (icon_of_window window) window.name
            is_focus
      | None -> ())
  | cmd -> failwith Format.(sprintf "Unknown command `%s'" cmd)
