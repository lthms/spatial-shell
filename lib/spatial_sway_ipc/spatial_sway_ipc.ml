let socket_path = "/tmp/spatial-sway.socket"

type t =
  | Move_left
  | Move_right
  | Move_window_left
  | Move_window_right
  | Toggle_full_view
  | Incr_maximum_visible_space
  | Decr_maximum_visible_space

let to_int32 = function
  | Move_left -> 0l
  | Move_right -> 1l
  | Move_window_left -> 2l
  | Move_window_right -> 3l
  | Toggle_full_view -> 4l
  | Incr_maximum_visible_space -> 5l
  | Decr_maximum_visible_space -> 6l

let of_int32 = function
  | 0l -> Some Move_left
  | 1l -> Some Move_right
  | 2l -> Some Move_window_left
  | 3l -> Some Move_window_right
  | 4l -> Some Toggle_full_view
  | 5l -> Some Incr_maximum_visible_space
  | 6l -> Some Decr_maximum_visible_space
  | _ -> None

let of_int32_exn i =
  match of_int32 i with
  | Some res -> res
  | None -> raise (Invalid_argument "Spatial_sway_ipc.of_int32_exn")
