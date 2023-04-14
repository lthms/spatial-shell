(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

let pp_windows_seq fmt l =
  Format.(
    fprintf fmt "%a"
      (pp_print_list
         ~pp_sep:(fun fmt () -> pp_print_string fmt " ")
         pp_print_int)
      (List.map Int64.to_int l))
