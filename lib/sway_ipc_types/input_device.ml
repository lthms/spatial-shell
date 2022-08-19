type input_type =
  | Keyboard
  | Pointer
  | Touch
  | Tablet_tool
  | Tablet_pad
  | Switch

let input_type_decoder =
  Json_decoder.string_enum
    [
      ("keyboard", Keyboard);
      ("pointer", Pointer);
      ("touch", Touch);
      ("tablet_tool", Tablet_tool);
      ("tablet_pad", Tablet_pad);
      ("switch", Switch);
    ]

type t = {
  identifier : string;
  name : string;
  vendor : int64;
  product : int64;
  input_type : input_type;
  xkb_active_layout_name : string option;
  xkb_layout_names : string list option;
  xkb_active_layout_index : int64 option;
  scroll_factor : float option;
  libinput : Libinput.t option;
}

let decoder =
  let open Json_decoder in
  let open Syntax in
  let+ identifier = field "identifier" string
  and+ name = field "name" string
  and+ vendor = field "vendor" int64
  and+ product = field "product" int64
  and+ input_type = field "input_type" input_type_decoder
  and+ xkb_active_layout_name = field_opt "xkb_active_layout_name" string
  and+ xkb_layout_names = field_opt "xkb_active_layout_name" (list string)
  and+ xkb_active_layout_index = field_opt "xkb_active_layout_index" int64
  and+ scroll_factor = field_opt "scroll_factor" float
  and+ libinput = field_opt "libinput" Libinput.decoder in
  {
    identifier;
    name;
    vendor;
    product;
    input_type;
    xkb_active_layout_name;
    xkb_layout_names;
    xkb_active_layout_index;
    scroll_factor;
    libinput;
  }

type input_device = t
