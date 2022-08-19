module Map = Map.Make (String)

type t = Ribbon.t Map.t

let empty : t = Map.empty

let register_window default_full_view default_maximum_visible workspace window
    reg =
  Map.update workspace
    (fun workspace ->
      let ribbon =
        Option.value
          ~default:(Ribbon.empty default_full_view default_maximum_visible)
          workspace
      in
      Some (Ribbon.insert_window window ribbon))
    reg

let unregister = Map.remove
let find = Map.find
let find_opt = Map.find_opt
let update = Map.update
let get_list reg = reg |> Map.to_seq |> Seq.map fst |> List.of_seq

let pp fmt workspaces =
  let open Format in
  fprintf fmt "%a"
    (pp_print_list
       ~pp_sep:(fun fmt () -> pp_print_string fmt ", ")
       (fun fmt (x, r) -> fprintf fmt "%s: %a" x Ribbon.pp r))
    (Map.to_seq workspaces |> List.of_seq)
