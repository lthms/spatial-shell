type t = int32 * string
type raw_message = t

let int32_to_string x =
  let buffer = Bytes.create 4 in
  Bytes.set_int32_ne buffer 0 x;
  Bytes.to_string buffer

let string_to_int32 x =
  let buffer = Bytes.of_string x in
  Bytes.get_int32_ne buffer 0

let to_string ~magic_string (code, payload) =
  magic_string
  ^ int32_to_string (String.length payload |> Int32.of_int)
  ^ int32_to_string code ^ payload
