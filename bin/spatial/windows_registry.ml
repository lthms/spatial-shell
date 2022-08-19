module Map = Map.Make (Int64)

type info = { workspace : string; app_id : string }
type t = info Map.t

let empty : t = Map.empty
let register : int64 -> info -> t -> t = Map.add
let unregister = Map.remove
let find = Map.find

let pp_window fmt (id, { app_id; workspace }) =
  Format.fprintf fmt "{ id = %Ld; app_id = %s; workspace = %s }" id app_id
    workspace

let pp fmt windows =
  let open Format in
  fprintf fmt "%a"
    (pp_print_list ~pp_sep:(fun fmt () -> pp_print_string fmt ", ") pp_window)
    (Map.to_seq windows |> List.of_seq)
