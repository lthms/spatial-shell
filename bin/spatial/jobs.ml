(* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

let run f = ignore (Thread.create f ())
let shell cmd = run (fun () -> Unix.system cmd)

(** [spawn cmd] forks a new process, to execute [cmd] as a command for
    [/bin/sh]. In the parent process, returns the PID. *)
let spawn cmd =
  let pid = Unix.fork () in
  if pid = 0 then Unix.execv "/bin/sh" [| "/bin/sh"; "-c"; cmd |] else pid

let kill pid =
  run @@ fun () ->
  Unix.kill pid Sys.sigterm;
  Unix.waitpid [] pid
