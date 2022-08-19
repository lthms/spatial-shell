type t = {
  name : string;
  capabilities : int64;
  focus : int64;
  devices : Input_device.t list;
}

type seat = t

let decoder =
  let open Json_decoder in
  let open Syntax in
  let+ name = field "name" string
  and+ capabilities = field "capabilities" int64
  and+ focus = field "focus" int64
  and+ devices = field "devices" @@ list Input_device.decoder in
  { name; capabilities; focus; devices }
