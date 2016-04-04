
(** *)

module type S =
  sig
    type key
    type 'a t

    val init : size: int -> witness: key -> 'a t
    val in_cache : 'a t -> key -> bool
    val get : 'a t -> key -> (unit -> 'a) -> 'a
  end

module Make (T:Map.OrderedType) =
  struct
    type key = T.t

    module M = Map.Make(T)
    type 'a v = { v: 'a; pos: int ref }
    type key_node = { key : key; pos: int ref }

    type 'a t =
        { mutable map: 'a v M.t ;
          keys: key_node array ;
        }

    let init ~size ~witness =
      { map = M.empty ;
        keys = Array.make size {key = witness ; pos = ref (-1)} ;
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

    let get t k f =
      match M.find k t.map with
      | exception Not_found ->
        let v = f () in
        insert t k v;
        v
      | { v ; pos } -> to_head t pos; v

  end