open Spatial_ipc

let icon glyph =
  Format.sprintf {|<span font="JetBrainsMono Nerd Font">%s</span>|} glyph

let icon_of_window window =
  match window.app_id with
  | "firefox" -> icon ""
  | "kitty" -> icon ""
  | "Slack" -> ""
  | "emacs" -> ""
  | "neovide" -> ""
  | "chromium" -> ""
  | _ -> ""

let icon_of_workspace = function
  | None -> icon "◯"
  | Some window -> icon_of_window window

let () =
  match Sys.argv.(1) with
  | "config" ->
      let reply = send_command Get_workspace_config in
      Format.printf "%s"
        (if reply.layout = Maximize then icon "" else icon "")
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
