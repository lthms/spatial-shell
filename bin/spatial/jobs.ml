let run f = ignore (Thread.create f ())
let shell cmd = run (fun () -> Unix.system cmd)
