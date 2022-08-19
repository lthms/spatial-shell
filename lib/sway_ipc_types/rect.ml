type t = { x : int64; y : int64; width : int64; height : int64 }
type rect = t

let decoder =
  let open Json_decoder.Syntax in
  let open Json_decoder in
  let+ x = field "x" int64
  and+ y = field "y" int64
  and+ width = field "width" int64
  and+ height = field "height" int64 in
  { x; y; width; height }
