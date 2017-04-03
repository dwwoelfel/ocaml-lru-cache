(*********************************************************************************)
(*                OCaml-lru-cache                                                *)
(*                                                                               *)
(*    Copyright (C) 2016 Institut National de Recherche en Informatique          *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the BSD3 License.                                    *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                       *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*                                                                               *)
(*********************************************************************************)

(** *)

module type Key =
  sig
    type t
    val compare : t -> t -> int
    val witness : t
  end

module type S =
  sig
    type key
    type 'a monad
    type 'a t

    val init : ?validate:('a monad -> bool monad) -> size: int -> 'a t
    val in_cache : 'a t -> key -> bool
    val get : 'a t ->
      ?validate:('a monad -> bool monad) -> key -> (key -> 'a monad) -> 'a monad
  end

module type Monad =
  sig
    type 'a t
    val bind: 'a t -> ('a -> 'b t) -> 'b t
    val return : 'a -> 'a t
  end

module Make_with_monad (Mo:Monad) (K:Key) =
  struct
    type key = K.t

    module M = Map.Make(K)
    type 'a v = { v: 'a Mo.t; pos: int ref }
    type key_node = { key : key; pos: int ref }

    type 'a t =
        { mutable map: 'a v M.t ;
          keys: key_node array ;
          validate : 'a Mo.t -> bool Mo.t;
        }
    type 'a monad = 'a Mo.t

    let init ?(validate=fun _ -> Mo.return true) ~size =
      { map = M.empty ;
        keys = Array.make size {key = K.witness ; pos = ref (-1)} ;
        validate ;
      }

    let remove_last t =
      let len = Array.length t.keys in
      let k = t.keys.(len - 1) in
      t.map <- M.remove k.key t.map

    let insert t key v =
      let size =
        let size = M.cardinal t.map in
        if size >= Array.length t.keys then
          ( remove_last t ; size - 1)
        else
          size
      in
      let pos = ref 0 in
      Array.blit t.keys 0 t.keys 1 size ;
      for i = 1 to (* 1 +*) size (* - 1 *) do
        t.keys.(i).pos := i ;
      done;
      t.keys.(0) <- { key ; pos } ;
      t.map <- M.add key { v ; pos } t.map

    let to_head t pos =
      match !pos with
        0 -> ()
      | p ->
          let v = t.keys.(p) in
          Array.blit t.keys 0 t.keys 1 p ;
          for i = 1 to (* 1 + *) p (* - 1 *) do
            t.keys.(i).pos := i ;
          done;
          v.pos := 0 ;
          t.keys.(0) <- v

    let in_cache t k =
      match M.find k t.map with
      | exception Not_found -> false
      | _ -> true

    let get t ?(validate=t.validate) k f =
      match M.find k t.map with
      | exception Not_found ->
        let v = f k in
        Mo.bind (validate v)
          (function
           | true -> insert t k v; v
           | false -> v)
      | { v ; pos } -> to_head t pos; v

  end

module No_monad =
  struct type 'a t = 'a let bind x f = f x let return x = x end

module Make (K:Key) = Make_with_monad(No_monad) (K)
