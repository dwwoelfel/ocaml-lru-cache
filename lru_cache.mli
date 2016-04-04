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

 (** Simple Least Recently Used cache implementation. *)

module type S =
  sig
    type key

    (** The type of cache from keys of type [key] to values of
      type ['a]. Cache access must be protected by mutex in a
      multithread environment. This is not needed when using
      Async or Lwt. In these cases, the computation function passed
      to {!get} should return a [Deferred.t] of [Lwt.t].
    *)
    type 'a t

    (** [size] is the maximum number of entries in the cache.
      [witness] is a key required to initialiaze the cache content. *)
    val init : size: int -> witness: key -> 'a t

    (** Whether the value associate to the given key is in the cache. *)
    val in_cache : 'a t -> key -> bool

    (** [get cache key compute] returns the value associated to
      [key] in the cache and set this key as the most recently used.
      If no value is associated to this key, remove the least
      recently used (key,value) pair from the cache (if the cache is
      full) and add (key, [compute key]), setting this pair as the
      most recently used.
    *)
    val get : 'a t -> key -> (key -> 'a) -> 'a
  end

module Make (T:Map.OrderedType) :
  S with type key = T.t
