# c2ffi-ruby

[c2ffi](https://github.com/rpav/c2ffi) - FFI binding generator - for Ruby

:construction: Under development

# installation

```sh
gem install c2ffi
```

## Usage

First, produce a `spec` file using `c2ffi`:

```sh
cd example/simple/
c2ffi -M macros.h -o example.json example.h
c2ffi -o macros.json macros.h
```

Now you can generate a file manually with the included tool,
`c2ffi-ruby`, as follows:

```sh
c2ffi-ruby -M Example -l ex1,ex2 -o simple.rb *.json
```

This produces the `simple.rb` file, as included.  Realistically, you
should integrate this into your build process; you can either use this
tool, or call C2FFI::Parser.parse directly.

```ruby
C2FFI::Parser.parse(module_name, lib_or_libs, spec_array, io = $stdout)
```
