require_relative '../test_helper'

module C2FFI4RB
  class ParserTest < Minitest::Test
    def test_make_struct_with_simple_struct
      parser = C2FFI4RB::Parser.new
      form = { tag: 'struct',
               ns: 0,
               name: 'GTestSuite',
               id: 0,
               location: '/path/to/include/glib-2.0/glib/gtestutils.h:36:16',
               "bit-size": 0,
               "bit-alignment": 0,
               fields: [] }
      assert_equal "class Gtestsuite < FFI::Struct\nend", parser.send(:make_struct, form)
    end
  end
end
