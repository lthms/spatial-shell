(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

open Mltp_ipc

let socket_path = "/tmp/spatial-sway.socket"
let magic_string = "spatial-ipc"

type direction = Left | Right

let direction_of_string_opt = function
  | "left" -> Some Left
  | "right" -> Some Right
  | _ -> None

let direction_to_string = function Left -> "left" | Right -> "right"

type switch = On | Off | Toggle

let switch_of_string_opt = function
  | "on" -> Some On
  | "off" -> Some Off
  | "toggle" -> Some Toggle
  | _ -> None

let switch_to_string = function On -> "on" | Off -> "off" | Toggle -> "toggle"

type operation = Incr | Decr

let operation_of_string_opt = function
  | "increment" -> Some Incr
  | "decrement" -> Some Decr
  | _ -> None

let operation_to_string = function Incr -> "increment" | Decr -> "decrement"

type command =
  | Focus of direction
  | Move of direction
  | Maximize of switch
  | Split of operation

let ( <$> ) = Option.map

let command_of_string str =
  String.split_on_char ' ' str
  |> List.filter (function "" -> false | _ -> true)
  |> function
  | [ "focus"; dir ] -> (fun x -> Focus x) <$> direction_of_string_opt dir
  | [ "move"; dir ] -> (fun x -> Move x) <$> direction_of_string_opt dir
  | [ "maximize"; switch ] ->
      (fun x -> Maximize x) <$> switch_of_string_opt switch
  | [ "split"; op ] -> (fun x -> Split x) <$> operation_of_string_opt op
  | _ -> None

let command_of_string_exn str =
  match command_of_string str with
  | Some x -> x
  | None -> raise (Invalid_argument "Spatial_sway_ipc.command_of_string_exn")

let command_to_string = function
  | Focus dir -> Format.sprintf "focus %s" (direction_to_string dir)
  | Move dir -> Format.sprintf "move %s" (direction_to_string dir)
  | Maximize switch -> Format.sprintf "maximize %s" (switch_to_string switch)
  | Split op -> Format.sprintf "split %s" (operation_to_string op)

type 'a t = Run_command : command -> unit t

let reply_to_string : type a. a t -> a -> string =
 fun cmd reply -> match (cmd, reply) with Run_command _, () -> ""

let reply_of_string : type a. a t -> string -> a option =
 fun cmd reply ->
  match (cmd, reply) with Run_command _, "" -> Some () | _, _ -> None

let reply_of_string_exn cmd reply =
  match reply_of_string cmd reply with
  | Some x -> x
  | None -> failwith "cannot parse reply"

let to_raw_message : type a. a t -> Raw_message.t = function
  | Run_command cmd -> (0l, command_to_string cmd)

type packed = Packed : 'a t -> packed

let of_raw_message (op, payload) =
  match op with
  | 0l -> (fun x -> Packed (Run_command x)) <$> command_of_string payload
  | _ -> None

exception Spatial_ipc_error of Socket.error

type socket = Socket.socket

let connect () : socket Lwt.t = Socket.connect socket_path
let close socket = Socket.close socket

let trust_spatial f =
  let open Lwt.Syntax in
  let* x = f () in
  match x with Ok x -> Lwt.return x | Error e -> raise (Spatial_ipc_error e)

let with_socket f = Socket.with_socket socket_path f

let socket_from_option = function
  | Some socket -> Lwt.return socket
  | None -> connect ()

let send_command ?socket cmd =
  let open Lwt.Syntax in
  let* socket = socket_from_option socket in
  let ((op, _) as raw) = to_raw_message cmd in
  let* () =
    trust_spatial @@ fun () -> Socket.write_raw_message ~magic_string socket raw
  in
  let* op', payload =
    trust_spatial @@ fun () -> Socket.read_raw_message ~magic_string socket
  in
  assert (op = op');
  Lwt.return @@ reply_of_string_exn cmd payload

type ('a, 'b) handler = { handler : 'r. 'a -> 'r t -> ('b option * 'r) Lwt.t }

let handle_next_command ~socket input { handler } =
  let open Lwt.Syntax in
  let* res = Socket.read_raw_message ~magic_string socket in
  match res with
  | Ok ((op, _) as raw) -> (
      let cmd = of_raw_message raw in
      match cmd with
      | Some (Packed cmd) ->
          let* output, reply = handler input cmd in
          let* _ =
            Socket.write_raw_message ~magic_string socket
              (op, reply_to_string cmd reply)
          in
          Lwt.return output
      | None ->
          let* _ = Socket.write_raw_message ~magic_string socket (op, "") in
          Lwt.return None)
  | Error _ ->
      let* _ = Socket.write_raw_message ~magic_string socket (-1l, "") in
      Lwt.return None

let create_server () = Socket.create_server socket_path
