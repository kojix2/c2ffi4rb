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

    def test_make_struct_with_form_which_has_anonymous_field
      parser = C2FFI4RB::Parser.new
      form = { tag: 'struct', ns: 0, name: 'Sigcontext', id: 0,
               location: '/path/to/include/bits/modified_sigcontext.h:139:8',
               "bit-size": 2048,
               "bit-alignment": 64,
               fields: [{ tag: 'field',
                          name: '', # empty name here!
                          "bit-offset": 1472, "bit-size": 64, "bit-alignment": 64,
                          type: { tag: 'union', ns: 0, name: '', id: 84, location: '/path/to/include/bits/sigcontext.h:167:17', "bit-size": 64, "bit-alignment": 64,
                                  fields: [{ tag: 'field', name: 'fpstate', "bit-offset": 0, "bit-size": 64, "bit-alignment": 64,
                                             type: { tag: ':pointer', type: { tag: ':struct', name: '_fpstate', id: 85 } } },
                                           { tag: 'field', name: '__fpstate_word', "bit-offset": 0, "bit-size": 64, "bit-alignment": 64,
                                             type: { tag: '__uint64_t' } }] } }] }
      assert_equal "class Sigcontext < FFI::Struct\n  layout \\\n    :anon_field_0, Anon_Type_1\nend", parser.send(:make_struct, form)
    end
  end
end
