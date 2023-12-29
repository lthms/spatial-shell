(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

type 'a t = { decoder : 'a Json_decoder.t; encoder : 'a Json_encoder.t }

let to_json_exn jsoner value = jsoner.encoder value
let to_json jsoner value = try Some (jsoner.encoder value) with _ -> None

let to_string_exn ~minify jsoner value =
  Ezjsonm.value_to_string ~minify (to_json_exn jsoner value)

let to_string ~minify jsoner value =
  try Some (to_string_exn ~minify jsoner value) with _ -> None

let from_string_exn jsoner string =
  jsoner.decoder (Ezjsonm.value_from_string string)

let from_string jsoner value =
  try Some (from_string_exn jsoner value) with _ -> None

let conv from_value to_value jsoner =
  {
    decoder = (fun json -> jsoner.decoder json |> to_value);
    encoder = (fun value -> from_value value |> jsoner.encoder);
  }

let string = { decoder = Json_decoder.string; encoder = Json_encoder.string }

let string_enum l =
  { encoder = Json_encoder.string_enum l; decoder = Json_decoder.string_enum l }

let list { decoder; encoder } =
  { decoder = Json_decoder.list decoder; encoder = Json_encoder.list encoder }

let int64 = { decoder = Json_decoder.int64; encoder = Json_encoder.int64 }
let int = { decoder = Json_decoder.int; encoder = Json_encoder.int }
let bool = { decoder = Json_decoder.bool; encoder = Json_encoder.bool }

type 'a field = {
  name : string;
  field_encoder : 'a -> Ezjsonm.value -> Ezjsonm.value;
  field_decoder : 'a Json_decoder.t;
}

let req name { encoder; decoder } =
  {
    name;
    field_encoder = Json_encoder.field name encoder;
    field_decoder = Json_decoder.field name decoder;
  }

let opt name { encoder; decoder } =
  {
    name;
    field_encoder = Json_encoder.field_opt name encoder;
    field_decoder = Json_decoder.field_opt name decoder;
  }

let obj1 f =
  {
    encoder = (fun value -> f.field_encoder value (`O []));
    decoder = (fun json -> f.field_decoder json);
  }

let obj2 f1 f2 =
  {
    encoder =
      (fun (v1, v2) -> `O [] |> f1.field_encoder v1 |> f2.field_encoder v2);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder and+ v2 = f2.field_decoder in
       (v1, v2));
  }

let obj3 f1 f2 f3 =
  {
    encoder =
      (fun (v1, v2, v3) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder in
       (v1, v2, v3));
  }

let obj4 f1 f2 f3 f4 =
  {
    encoder =
      (fun (v1, v2, v3, v4) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder in
       (v1, v2, v3, v4));
  }

let obj5 f1 f2 f3 f4 f5 =
  {
    encoder =
      (fun (v1, v2, v3, v4, v5) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4 |> f5.field_encoder v5);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder
       and+ v5 = f5.field_decoder in
       (v1, v2, v3, v4, v5));
  }

let obj6 f1 f2 f3 f4 f5 f6 =
  {
    encoder =
      (fun (v1, v2, v3, v4, v5, v6) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4 |> f5.field_encoder v5
        |> f6.field_encoder v6);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder
       and+ v5 = f5.field_decoder
       and+ v6 = f6.field_decoder in
       (v1, v2, v3, v4, v5, v6));
  }

let obj7 f1 f2 f3 f4 f5 f6 f7 =
  {
    encoder =
      (fun (v1, v2, v3, v4, v5, v6, v7) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4 |> f5.field_encoder v5
        |> f6.field_encoder v6 |> f7.field_encoder v7);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder
       and+ v5 = f5.field_decoder
       and+ v6 = f6.field_decoder
       and+ v7 = f7.field_decoder in
       (v1, v2, v3, v4, v5, v6, v7));
  }

let obj8 f1 f2 f3 f4 f5 f6 f7 f8 =
  {
    encoder =
      (fun (v1, v2, v3, v4, v5, v6, v7, v8) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4 |> f5.field_encoder v5
        |> f6.field_encoder v6 |> f7.field_encoder v7 |> f8.field_encoder v8);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder
       and+ v5 = f5.field_decoder
       and+ v6 = f6.field_decoder
       and+ v7 = f7.field_decoder
       and+ v8 = f8.field_decoder in
       (v1, v2, v3, v4, v5, v6, v7, v8));
  }

let obj9 f1 f2 f3 f4 f5 f6 f7 f8 f9 =
  {
    encoder =
      (fun (v1, v2, v3, v4, v5, v6, v7, v8, v9) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4 |> f5.field_encoder v5
        |> f6.field_encoder v6 |> f7.field_encoder v7 |> f8.field_encoder v8
        |> f9.field_encoder v9);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder
       and+ v5 = f5.field_decoder
       and+ v6 = f6.field_decoder
       and+ v7 = f7.field_decoder
       and+ v8 = f8.field_decoder
       and+ v9 = f9.field_decoder in
       (v1, v2, v3, v4, v5, v6, v7, v8, v9));
  }

let obj10 f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 =
  {
    encoder =
      (fun (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) ->
        `O [] |> f1.field_encoder v1 |> f2.field_encoder v2
        |> f3.field_encoder v3 |> f4.field_encoder v4 |> f5.field_encoder v5
        |> f6.field_encoder v6 |> f7.field_encoder v7 |> f8.field_encoder v8
        |> f9.field_encoder v9 |> f10.field_encoder v10);
    decoder =
      (let open Json_decoder.Syntax in
       let+ v1 = f1.field_decoder
       and+ v2 = f2.field_decoder
       and+ v3 = f3.field_decoder
       and+ v4 = f4.field_decoder
       and+ v5 = f5.field_decoder
       and+ v6 = f6.field_decoder
       and+ v7 = f7.field_decoder
       and+ v8 = f8.field_decoder
       and+ v9 = f9.field_decoder
       and+ v10 = f10.field_decoder in
       (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10));
  }

let merge_objs j1 j2 =
  {
    encoder =
      (fun (v1, v2) ->
        match (j1.encoder v1, j2.encoder v2) with
        | `O l1, `O l2 -> `O (l1 @ l2)
        | _ -> raise (Invalid_argument "merge_objs: expected objects"));
    decoder = (fun json -> (j1.decoder json, j2.decoder json));
  }

module Decoding = struct
  type 'a jsoner = 'a t

  let from_jsoner { decoder; _ } = decoder

  include Json_decoder
end
