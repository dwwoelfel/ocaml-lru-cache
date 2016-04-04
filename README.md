# ocaml-lru-cache

ocaml-lru-cache is a simple OCaml implementation of a cache using
the [Least Recently Used (LRU)](https://en.wikipedia.org/wiki/Cache_algorithms)
strategy.

## Installation

Install the library via [OPAM][opam]:

[opam]: http://opam.ocaml.org/

```bash
opam install lru-cache
```

### Examples

See the `test_lwt.ml` for an example using Lwt to compute cached values.
To compile the example, [Lwt](http://ocsigen.org/lwt/) must be installed.

```bash
make test
```
## License

BSD3, see LICENSE file for its text.
