BAR = 14

QUUX = "abc"

attach_variable :SomeExtern, :SomeExtern, :int

attach_function 'blah', [
  :pointer,
], :void

attach_variable :foo, :foo, :string

class My_Point < FFI::Union
  layout \
    :x, :int,
    :y, :int,
    :odd_value, [:int, 15]
end

My_Point_T = My_Point

class Anon_Type_1 < FFI::Union
  layout \
    :a, :int,
    :b, :int
end

Anonymous_T = Anon_Type_1

class Anon_Type_2 < FFI::Union
  layout \
    :x, :double
end

enum :anon_type_3, [
  :X, 0,
  :Y, 1,
  :Z, 2,
]

class C_Some_Internal_Struct < FFI::Union
  layout \
    :a, Anon_Type_2,
    :x, :int,
    :c, :char,
    :m, :anon_type_3
end

class Some_Struct < FFI::Union
  layout \
    :s, C_Some_Internal_Struct,
    :blah, :int
end

class C_Some_Internal_Struct < FFI::Union
  layout \
    :a, Anon_Type_4,
    :x, :int,
    :c, :char,
    :m, :anon_type_5
end

enum :anon_type_6, [
  :X, 0,
  :Y, 1,
  :Z, 2,
]

Some_Struct_T = Some_Struct

class My_Union < FFI::Union
  layout \
    :c, :char,
    :i, :int,
    :d, :double
end

enum :some_values, [
  :a_value, 0,
  :another_value, 1,
  :yet_another_value, 2,
]

attach_function 'do_something', [
  :pointer,
  :int,
  :int,
], :void

BAR = 14

QUUX = "abc"

attach_variable :SomeExtern, :SomeExtern, :int

attach_function 'blah', [
  :pointer,
], :void

attach_variable :foo, :foo, :string

class My_Point < FFI::Union
  layout \
    :x, :int,
    :y, :int,
    :odd_value, [:int, 15]
end

My_Point_T = My_Point

class Anon_Type_7 < FFI::Union
  layout \
    :a, :int,
    :b, :int
end

Anonymous_T = Anon_Type_7

class Anon_Type_8 < FFI::Union
  layout \
    :x, :double
end

enum :anon_type_9, [
  :X, 0,
  :Y, 1,
  :Z, 2,
]

class C_Some_Internal_Struct < FFI::Union
  layout \
    :a, Anon_Type_8,
    :x, :int,
    :c, :char,
    :m, :anon_type_9
end

class Some_Struct < FFI::Union
  layout \
    :s, C_Some_Internal_Struct,
    :blah, :int
end

class C_Some_Internal_Struct < FFI::Union
  layout \
    :a, Anon_Type_10,
    :x, :int,
    :c, :char,
    :m, :anon_type_11
end

enum :anon_type_12, [
  :X, 0,
  :Y, 1,
  :Z, 2,
]

Some_Struct_T = Some_Struct

class My_Union < FFI::Union
  layout \
    :c, :char,
    :i, :int,
    :d, :double
end

enum :some_values, [
  :a_value, 0,
  :another_value, 1,
  :yet_another_value, 2,
]

attach_function 'do_something', [
  :pointer,
  :int,
  :int,
], :void
