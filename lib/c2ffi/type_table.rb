# frozen_string_literal: true

module C2FFI
  TYPE_TABLE = {
    unsigned-int: :uint,
    unsigned-char: :uchar,
    unsigned-long: :ulong,
    function-pointer: :pointer
  }.freeze
end