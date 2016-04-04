
 (** Simple Least Recently Used cache implementation. *)

module type S =
  sig
    type key
    type 'a t

    val init : size: int -> witness: key -> 'a t
    val in_cache : 'a t -> key -> bool
    val get : 'a t -> key -> (unit -> 'a) -> 'a
  end

module Make (T:Map.OrderedType) :
  S with type key = T.t
