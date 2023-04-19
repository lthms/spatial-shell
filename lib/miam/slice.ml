(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type t = { base : int; len : int; buffer : string }

let of_string buffer = { base = 0; len = String.length buffer; buffer }

let get slice i =
  if 0 <= i && i < slice.len then String.get slice.buffer (slice.base + i)
  else raise (Invalid_argument "Slice.get")

let take slice n =
  if 0 <= n && n <= slice.len then
    { base = slice.base; len = n; buffer = slice.buffer }
  else raise (Invalid_argument "Slice.take")

let drop slice n =
  if 0 <= n && n <= slice.len then
    { base = slice.base + n; len = slice.len - n; buffer = slice.buffer }
  else raise (Invalid_argument "Slice.drop")

let split slice i =
  if 0 <= i && i <= slice.len then (take slice i, drop slice i)
  else raise (Invalid_argument "Slice.split")

let equal_string slice string =
  try
    String.iteri (fun i c -> assert (get slice i = c)) string;
    true
  with Assert_failure _ -> false

let to_int slice =
  let char_to_int c =
    let x = Char.code c - Char.code '0' in
    assert (x < 10);
    x
  in
  let rec aux slice acc =
    if slice.len = 0 then acc
    else
      let c = get slice 0 in
      aux (drop slice 1) ((acc * 10) + char_to_int c)
  in
  aux slice 0

(** [to_string slice] copies the contents of [slice] in a newly allocated [string] *)
let to_string slice = String.sub slice.buffer slice.base slice.len
