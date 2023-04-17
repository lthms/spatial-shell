(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type 'a parser = Slice.t -> 'a * Slice.t

let return x slice = (x, slice)

let ( let+ ) parser f slice =
  let x, slice = parser slice in
  (f x, slice)

let ( and+ ) parser parser' slice =
  let x, slice = parser slice in
  let y, slice = parser' slice in
  ((x, y), slice)

let ( let* ) parser k slice =
  let x, slice = parser slice in
  k x slice

let ( <|> ) parser parser' slice = try parser slice with e -> parser' slice

let skip parser =
  let+ _ = parser in
  ()

let ( *> ) o p =
  let+ () = skip o and+ x = p in
  x

let ( <* ) o p =
  let+ x = o and+ () = skip p in
  x

let take n slice = Slice.split slice n

let string str =
  let+ x = take (String.length str) in
  assert (Slice.equal_string x str);
  ()

let char c slice =
  let x = Slice.get slice 0 in
  assert (x = c);
  ((), Slice.drop slice 1)

let take_while cond slice =
  let rec aux i =
    if i < slice.Slice.len && cond (Slice.get slice i) then aux (i + 1)
    else Slice.split slice i
  in
  aux 0

let int =
  let+ x =
    take_while (fun c ->
        let c = Char.code c in
        Char.code '0' <= c && c <= Char.code '9')
  in
  Slice.to_int x

let rec enum = function
  | (str, res) :: rst ->
      (let+ () = string str in
       res)
      <|> enum rst
  | [] -> fun slice -> raise (Invalid_argument "Parser.enum")

let run parser str =
  try Some (Slice.of_string str |> parser |> fst) with _ -> None

let whitespaces = skip @@ take_while (fun c -> c = ' ' || c = '\t')
let word str = whitespaces *> string str <* whitespaces

let empty slice =
  assert (slice.Slice.len = 0);
  ((), slice)
