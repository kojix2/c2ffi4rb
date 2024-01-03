require_relative 'test_helper'

class C2FFI4RBTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::C2FFI4RB::VERSION
  end

  def test_simple_fixtures
    Fixture.new(name: "simple",
                source_header: "example.h",
                macros_header: "macros.h",
                output_json: "example_original.json",
                macros_json: "macros_original.json",
                output_ruby: "simple.rb").test(self)
  end

  def test_cairo_fixtures
    Fixture.new(name: "cairo",
                source_header: Dir["#{`pkg-config --cflags-only-I cairo`.split.first[2..]}/**/cairo.h"].first,
                macros_header: "macros.h",
                output_json: "cairo_original.json",
                macros_json: "macros_original.json",
                output_ruby: "my_cairo.rb").test(self)
  end
end
