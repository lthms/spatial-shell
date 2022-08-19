type send_events = Enabled | Disabled | Disabled_on_external_mouse | Unknown

let send_events_decoder =
  Json_decoder.string_enum
    [
      ("enabled", Enabled);
      ("disabled", Disabled);
      ("disabled_on_external_mouse", Disabled_on_external_mouse);
      ("unknown", Unknown);
    ]

type tap = Enabled | Disabled | Unknown

let tap_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type tap_button_map = Lmr | Lrm | Unknown

let tap_button_map_decoder =
  Json_decoder.string_enum [ ("lmr", Lmr); ("lrm", Lrm); ("unknown", Unknown) ]

type tap_drag = Enabled | Disabled | Unknown

let tap_drag_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type tap_drag_lock = Enabled | Disabled | Unknown

let tap_drag_lock_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type accel_profile = None | Flat | Adaptive | Unknown

let accel_profile_decoder =
  Json_decoder.string_enum
    [
      ("none", None);
      ("flat", Flat);
      ("adaptive", Adaptive);
      ("unknown", Unknown);
    ]

type natural_scroll = Enabled | Disabled | Unknown

let natural_scroll_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type left_handed = Enabled | Disabled | Unknown

let left_handed_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type click_method = None | Button_areas | Clickfinger | Unknown

let click_method_decoder =
  Json_decoder.string_enum
    [
      ("none", None);
      ("button_areas", Button_areas);
      ("clickfinger", Clickfinger);
      ("unknown", Unknown);
    ]

type middle_emulation = Enabled | Disabled | Unknown

let middle_emulation_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type scroll_method = None | Two_fingers | Edge | On_button_down | Unknown

let scroll_method_decoder =
  Json_decoder.string_enum
    [
      ("none", None);
      ("two_fingers", Two_fingers);
      ("edge", Edge);
      ("on_button_down", On_button_down);
      ("unknown", Unknown);
    ]

type dwt = Enabled | Disabled | Unknown

let dwt_decoder =
  Json_decoder.string_enum
    [ ("enabled", Enabled); ("disabled", Disabled); ("unknown", Unknown) ]

type calibration_matrix = float * float * float * float * float * float

let calibration_matrix_decoder =
  let open Json_decoder in
  let open Syntax in
  let+ l = list float in
  match l with
  | [ a; b; c; d; e; f ] -> (a, b, c, d, e, f)
  | _ -> raise (Invalid_argument "calibration_matrix_decoder")

type t = {
  send_events : send_events option;
  tap : tap option;
  tap_button_map : tap_button_map option;
  tap_drag : tap_drag option;
  tap_drag_lock : tap_drag_lock option;
  accel_speed : float option;
  accel_profile : accel_profile option;
  natural_scroll : natural_scroll option;
  left_handed : left_handed option;
  click_method : click_method option;
  middle_emulation : middle_emulation option;
  scroll_method : scroll_method option;
  scroll_button : int64 option;
  dwt : dwt option;
  calibration_matrix : calibration_matrix option;
}

type libinput = t

let decoder =
  let open Json_decoder in
  let open Syntax in
  let+ send_events = field_opt "send_events" send_events_decoder
  and+ tap = field_opt "tap" tap_decoder
  and+ tap_button_map = field_opt "tap_button_map" tap_button_map_decoder
  and+ tap_drag = field_opt "tap_drag" tap_drag_decoder
  and+ tap_drag_lock = field_opt "tap_drag_lock" tap_drag_lock_decoder
  and+ accel_speed = field_opt "accel_speed" float
  and+ accel_profile = field_opt "accel_profile" accel_profile_decoder
  and+ natural_scroll = field_opt "natural_scroll" natural_scroll_decoder
  and+ left_handed = field_opt "left_handed" left_handed_decoder
  and+ click_method = field_opt "click_method" click_method_decoder
  and+ middle_emulation = field_opt "middle_emulation" middle_emulation_decoder
  and+ scroll_method = field_opt "scroll_method" scroll_method_decoder
  and+ scroll_button = field_opt "scroll_button" int64
  and+ dwt = field_opt "dwt" dwt_decoder
  and+ calibration_matrix =
    field_opt "calibration_matrix" calibration_matrix_decoder
  in
  {
    send_events;
    tap;
    tap_button_map;
    tap_drag;
    tap_drag_lock;
    accel_speed;
    accel_profile;
    natural_scroll;
    left_handed;
    click_method;
    middle_emulation;
    scroll_method;
    scroll_button;
    dwt;
    calibration_matrix;
  }
