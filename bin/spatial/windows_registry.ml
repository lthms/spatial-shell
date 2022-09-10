open Spatial_ipc
module Map = Map.Make (Int64)

type t = window_info Map.t

let empty : t = Map.empty
let register : int64 -> window_info -> t -> t = Map.add
let unregister = Map.remove
let find = Map.find
let find_opt = Map.find_opt

let pp_window fmt (id, { app_id; name; workspace }) =
  Format.fprintf fmt "{ id = %Ld; app_id = %s; name = %s; workspace = %s }" id
    name app_id workspace

let pp fmt windows =
  let open Format in
  fprintf fmt "%a"
    (pp_print_list ~pp_sep:(fun fmt () -> pp_print_string fmt ", ") pp_window)
    (Map.to_seq windows |> List.of_seq)
