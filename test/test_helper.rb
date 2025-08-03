# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require 'c2ffi4rb'
require 'fileutils'

require 'minitest/autorun'
require 'minitest/pride'

C2FFI = ENV['C2FFI'] || 'c2ffi'

Fixture = Struct.new(:name, :source_header, :macros_header, :output_json, :macros_json, :output_ruby,
                     keyword_init: true) do
  def test(test_class)
    fixtures_dir = File.join(__dir__, 'fixtures', name)
    temp_dir = File.join(__dir__, 'tmp', name)

    # Create temp directory for generated files
    FileUtils.mkdir_p(temp_dir)

    Dir.chdir(fixtures_dir) do
      # Generate files in temp directory
      temp_output_json = File.join(temp_dir, output_json)
      temp_macros_json = File.join(temp_dir, macros_json)
      temp_output_ruby = File.join(temp_dir, output_ruby)
      temp_macros_header = File.join(temp_dir, macros_header)

      test_class.assert system C2FFI, '-M', temp_macros_header, '-o', temp_output_json, source_header, exception: true
      test_class.assert system C2FFI, '-o', temp_macros_json, source_header, temp_macros_header, exception: true
      test_class.assert system "RUBYLIB=$PWD/lib:$RUBYLIB #{__dir__}/../exe/c2ffi4rb #{temp_output_json} #{temp_macros_json} > #{temp_output_ruby}",
                               exception: true
      test_class.assert system 'ruby', '-c', temp_output_ruby, exception: true
    end
  end
end
