let pp_windows_seq fmt l =
  Format.(
    fprintf fmt "%a"
      (pp_print_list
         ~pp_sep:(fun fmt () -> pp_print_string fmt " ")
         pp_print_int)
      (List.map Int64.to_int l))
