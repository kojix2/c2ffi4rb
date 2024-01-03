# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require 'c2ffi4rb'

require 'minitest/autorun'
require 'minitest/pride'

Fixture = Struct.new(:name, :source_header, :macros_header, :output_json, :macros_json, :output_ruby,
                     keyword_init: true) do
  def test(test_class)
    Dir.chdir(File.join(__dir__, "fixtures", name)) do
      test_class.assert system "c2ffi", "-M", macros_header, "-o", output_json, source_header, exception: true
      test_class.assert system "c2ffi", "-o", macros_json, source_header, macros_header, exception: true
      test_class.assert system "RUBYLIB=$PWD/lib:$RUBYLIB #{__dir__}/../exe/c2ffi4rb #{output_json} #{macros_json} > #{output_ruby}", exception: true
      test_class.assert system "ruby", "-c", output_ruby, exception: true
    end
  end
end
