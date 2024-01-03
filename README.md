# c2ffi4rb

[![Gem Version](https://badge.fury.io/rb/c2ffi4rb.svg)](https://badge.fury.io/rb/c2ffi4rb)
[![test](https://github.com/kojix2/c2ffi4rb/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/c2ffi4rb/actions/workflows/ci.yml)


[c2ffi](https://github.com/rpav/c2ffi) - FFI binding generator - for Ruby

## installation

```sh
gem install c2ffi4rb
```

## Usage

First, produce a `spec` file using `c2ffi`.

```sh
c2ffi -M macros.h -o example.json example.h
c2ffi -o macros.json macros.h
```

Next, use c2ffi4rb to generate ruby code.

```sh
c2ffi4rb example.json macro.json > simple.rb
```

Finally, improve simple.rb manually to complete the binding.

## Development

To run tests, install [c2ffi][c2ffi], [Cairo][cairo], and [pkg-config][pkg-config] in advance.
Then execute `rake test`.

[cairo]: https://www.cairographics.org/ "Cairo"
[pkg-config]: https://www.freedesktop.org/wiki/Software/pkg-config/ "freedesktop.org"
[c2ffi]: https://github.com/rpav/c2ffi "GitHub"

## Licence

- [LGPL-2](https://github.com/rpav/c2ffi-ruby/blob/master/c2ffi-ruby.gemspec)
