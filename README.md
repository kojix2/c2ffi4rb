# c2ffi-ruby

[c2ffi](https://github.com/rpav/c2ffi) - FFI binding generator - for Ruby

## Usage

First, produce a `spec` file using `c2ffi`:

```sh
cd example/simple/
c2ffi -M macros.h -o example.spec example.h
c2ffi -o macros.spec macros.h
```

Now you can generate a file manually with the included tool,
`exe/c2ffi-ruby`, as follows:

```sh
c2ffi-ruby -M Example -l ex1,ex2 -o simple.rb *.spec
```

This produces the `simple.rb` file, as included.  Realistically, you
should integrate this into your build process; you can either use this
tool, or call C2FFI::Parser.parse directly.

```ruby
C2FFI::Parser.parse(module_name, lib_or_libs, spec_array, io = $stdout)
```

Note that C2FFI::Parser doesn't actually parse JSON, but rather takes
an array of hashes.  In theory, you could use this to produce output
for any input format that is parsed in a similar manner.
