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

    # Create both fixtures and temp directories if they don't exist
    FileUtils.mkdir_p(fixtures_dir)
    FileUtils.mkdir_p(temp_dir)

    Dir.chdir(fixtures_dir) do
      # Generate files in temp directory
      temp_output_json = File.join(temp_dir, output_json)
      temp_macros_json = File.join(temp_dir, macros_json)
      temp_output_ruby = File.join(temp_dir, output_ruby)
      temp_macros_header = File.join(temp_dir, macros_header)

      # Create macros header if it doesn't exist (for Cairo test)
      File.write(macros_header, create_default_macros_header(name)) unless File.exist?(macros_header)

      test_class.assert system C2FFI, '-M', temp_macros_header, '-o', temp_output_json, source_header, exception: true
      test_class.assert system C2FFI, '-o', temp_macros_json, source_header, temp_macros_header, exception: true
      test_class.assert system "RUBYLIB=$PWD/lib:$RUBYLIB #{__dir__}/../exe/c2ffi4rb #{temp_output_json} #{temp_macros_json} > #{temp_output_ruby}",
                               exception: true
      test_class.assert system 'ruby', '-c', temp_output_ruby, exception: true
    end
  end

  private

  def create_default_macros_header(fixture_name)
    case fixture_name
    when 'cairo'
      <<~HEADER
        /* Cairo macros for testing */
        #include <cairo.h>

        /* Some common Cairo macros that might be defined */
        #define CAIRO_VERSION_MAJOR 1
        #define CAIRO_VERSION_MINOR 16
        #define CAIRO_VERSION_MICRO 0

        /* Test macros */
        #define CAIRO_TEST_CONSTANT 42
        #define CAIRO_PI 3.14159265359
      HEADER
    else
      "/* Default macros for #{fixture_name} */\n"
    end
  end
end
