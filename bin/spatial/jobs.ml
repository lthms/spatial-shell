let run f = ignore (Thread.create f ())
let shell cmd = run (fun () -> Unix.system cmd)

(** [spawn cmd] forks a new process, to execute [cmd] as a command for
    [/bin/sh]. In the parent process, returns the PID. *)
let spawn cmd =
  let pid = Unix.fork () in
  if pid = 0 then Unix.execv "/bin/sh" [| "/bin/sh"; "-c"; cmd |] else pid

let kill ?wait pid =
  run @@ fun () ->
  (match wait with Some wait -> Unix.sleepf wait | None -> ());
  Unix.kill pid Sys.sigterm;
  Unix.waitpid [] pid
