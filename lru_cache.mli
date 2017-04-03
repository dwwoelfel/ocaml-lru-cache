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

 (** Simple Least Recently Used cache implementation. *)

(** Representation and comparison of keys, and a witness value
  required to initialize cache instances. *)
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

    (** The type of cache from keys of type [key] to values of
      type ['a]. Cache access must be protected by mutex in a
      multithread environment. This is not needed when using
      Async or Lwt. In these cases, the computation function passed
      to {!get} should return a [Deferred.t] of [Lwt.t].
    *)
    type 'a t

    (** [size] is the maximum number of entries in the cache.
         @param validate an optional function which returns whether
         a computed value must be kept in cache. Default function
         always returns [true].
    *)
    val init : ?validate:('a monad -> bool monad) -> size: int -> 'a t

    (** Whether the value associate to the given key is in the cache. *)
    val in_cache : 'a t -> key -> bool

    (** [get cache key compute] returns the value associated to
      [key] in the cache and set this key as the most recently used.
      If no value is associated to this key, remove the least
      recently used (key,value) pair from the cache (if the cache is
      full) and add (key, [compute key]), setting this pair as the
      most recently used.
      @param validate an optional function which returns whether
      a computed value must be kept in cache. Default function
      is the [validate] function given to {!init}.
    *)
    val get : 'a t ->
      ?validate:('a monad -> bool monad) -> key -> (key -> 'a monad) -> 'a monad
  end

module type Monad =
  sig
    type 'a t
    val bind: 'a t -> ('a -> 'b t) -> 'b t
    val return : 'a -> 'a t
  end

module Make_with_monad (M:Monad) (K:Key) :
  S with type key = K.t and type 'a monad = 'a M.t

module Make (K:Key) : S with type key = K.t and type 'a monad = 'a
