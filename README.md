# c2ffi4rb

[![Gem Version](https://badge.fury.io/rb/c2ffi4rb.svg)](https://badge.fury.io/rb/c2ffi4rb)
[![test](https://github.com/kojix2/c2ffi4rb/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/c2ffi4rb/actions/workflows/ci.yml)


[c2ffi](https://github.com/rpav/c2ffi) - FFI binding generator - for Ruby

# installation

```sh
gem install c2ffi4rb
```

## Usage

First, produce a `spec` file using `c2ffi`:

```sh
c2ffi -M macros.h -o example.json example.h
c2ffi -o macros.json macros.h
```

Now you can generate a file manually with the included tool,
`c2ffi-ruby`, as follows:

```sh
c2ffi4rb example.json macro.json > simple.rb
```

This produces the `simple.rb` file, as included.

## Licence

- [LGPL-2](https://github.com/rpav/c2ffi-ruby/blob/master/c2ffi-ruby.gemspec)
