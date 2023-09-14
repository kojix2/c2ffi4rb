# c2ffi4rb

[c2ffi](https://github.com/rpav/c2ffi) - FFI binding generator - for Ruby

:construction: Under development

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

This produces the `simple.rb` file, as included.  Realistically, you
should integrate this into your build process; you can either use this
tool, or call C2FFI::Parser.parse directly.

```ruby
C2FFI::Parser.parse(module_name, lib_or_libs, spec_array, io = $stdout)
```

## Licence

* [LGPL-2](https://github.com/rpav/c2ffi-ruby/blob/master/c2ffi-ruby.gemspec)