(*********************************************************************************)
(*                OCaml-lru-cache                                                *)
(*                                                                               *)
(*    Copyright (C) 2016 Institut National de Recherche en Informatique          *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU Lesser General Public License version        *)
(*    3 as published by the Free Software Foundation.                            *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU Lesser General Public           *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*                                                                               *)
(*********************************************************************************)

(** *)

module I = struct type t = int let compare x y = x - y end
module Cache = Lru_cache.Make(I)

let (cache : string Lwt.t Cache.t) = Cache.init ~size: 3 ~witness: 0

open Lwt.Infix

let print str = Lwt_io.write_line Lwt_io.stdout str

let f n =
  print (Printf.sprintf "computing f %d" n) >>= fun () ->
  Lwt_unix.sleep 2. >>= fun () -> Lwt.return (string_of_int n)

let run () =
  let go n =
    Lwt_unix.sleep 0.1 >>= fun () ->
      (if Cache.in_cache cache n then
         print (Printf.sprintf "f %d is in cache" n)
       else
         print (Printf.sprintf "f %d is in not in cache" n)
      ) >>= fun () ->
      Cache.get cache n (fun () -> f n) >>=
      fun res -> Lwt.return (n, res)
  in
  Lwt_list.map_p go
    [ 1 ; 2 ; 3 ; 3 ; 4 ; 1 ; 1 ; 1 ; 2 ; 5 ; 5 ; 5 ; 2 ; 3 ]

let l = Lwt_main.run (run ())
let () = List.iter
  (fun (n, str) -> print_endline (Printf.sprintf "%d -> %s" n str))
  l




    