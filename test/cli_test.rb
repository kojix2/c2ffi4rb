require_relative 'test_helper'
require 'tempfile'
require 'json'

class CLITest < Minitest::Test
  def setup
    @cli_path = File.join(__dir__, '..', 'exe', 'c2ffi4rb')
  end

  def test_version_option
    output = `ruby #{@cli_path} -v`
    assert_equal 0, $?.exitstatus
    assert_includes output, C2FFI4RB::VERSION
  end

  def test_help_option
    output = `ruby #{@cli_path} -h`
    assert_equal 0, $?.exitstatus
    assert_includes output, 'Usage: c2ffi4rb'
    assert_includes output, '--help'
    assert_includes output, '--version'
    assert_includes output, '--table'
  end

  def test_no_arguments_with_tty
    # When no arguments and stdin is a tty, should show help and exit with error
    # Skip this test in CI environments where TTY behavior is different
    skip "TTY behavior test not reliable in CI environments" if ENV['CI']
    
    output = `ruby #{@cli_path} 2>&1`
    assert_equal 1, $?.exitstatus
    assert_includes output, "Usage: c2ffi4rb"
  end

  def test_simple_json_processing
    # Create a simple JSON input
    json_data = [
      { tag: 'const', name: 'TEST_CONST', type: { tag: ':int' }, value: 42 }
    ]

    Tempfile.create(['test_input', '.json']) do |file|
      file.write(JSON.generate(json_data))
      file.flush

      output = `ruby #{@cli_path} #{file.path}`
      assert_equal 0, $?.exitstatus
      assert_includes output, 'TEST_CONST = 42'
    end
  end

  def test_multiple_json_files
    # Create two JSON files
    json1 = [{ tag: 'const', name: 'CONST1', type: { tag: ':int' }, value: 1 }]
    json2 = [{ tag: 'const', name: 'CONST2', type: { tag: ':int' }, value: 2 }]

    Tempfile.create(['test1', '.json']) do |file1|
      Tempfile.create(['test2', '.json']) do |file2|
        file1.write(JSON.generate(json1))
        file1.flush
        file2.write(JSON.generate(json2))
        file2.flush

        output = `ruby #{@cli_path} #{file1.path} #{file2.path}`
        assert_equal 0, $?.exitstatus
        assert_includes output, 'CONST1 = 1'
        assert_includes output, 'CONST2 = 2'
      end
    end
  end

  def test_type_conversion_table
    # Create a type conversion table
    json_data = [
      { tag: 'typedef', name: 'custom_type', type: { tag: ':custom_int' } }
    ]

    Tempfile.create(['input', '.json']) do |json_file|
      Tempfile.create(['table', '.tsv']) do |table_file|
        json_file.write(JSON.generate(json_data))
        json_file.flush

        table_file.write(":custom_int\t:long\n")
        table_file.flush

        output = `ruby #{@cli_path} -t #{table_file.path} #{json_file.path}`
        assert_equal 0, $?.exitstatus
        assert_includes output, 'typedef :long, :custom_type'
      end
    end
  end

  def test_type_table_with_comments
    # Test that comments in type table are ignored
    json_data = [
      { tag: 'typedef', name: 'test_type', type: { tag: ':test' } }
    ]

    Tempfile.create(['input', '.json']) do |json_file|
      Tempfile.create(['table', '.tsv']) do |table_file|
        json_file.write(JSON.generate(json_data))
        json_file.flush

        table_file.write("# This is a comment\n:test\t:int\n# Another comment\n")
        table_file.flush

        output = `ruby #{@cli_path} -t #{table_file.path} #{json_file.path}`
        assert_equal 0, $?.exitstatus
        assert_includes output, 'typedef :int, :test_type'
      end
    end
  end

  def test_invalid_json_file
    Tempfile.create(['invalid', '.json']) do |file|
      file.write('invalid json content')
      file.flush

      `ruby #{@cli_path} #{file.path} 2>&1`
      refute_equal 0, $?.exitstatus
    end
  end

  def test_nonexistent_file
    `ruby #{@cli_path} nonexistent_file.json 2>&1`
    refute_equal 0, $?.exitstatus
  end

  def test_stdin_input_with_pipe
    json_data = [
      { tag: 'const', name: 'STDIN_CONST', type: { tag: ':int' }, value: 99 }
    ]

    json_string = JSON.generate(json_data)
    output = `echo '#{json_string}' | ruby #{@cli_path}`
    assert_equal 0, $?.exitstatus
    assert_includes output, 'STDIN_CONST = 99'
  end

  def test_empty_stdin_input
    # Test that empty stdin doesn't cause JSON parse error
    output = `echo '' | ruby #{@cli_path} 2>&1`
    assert_equal 0, $?.exitstatus
    # Should not contain JSON parse error
    refute_includes output.downcase, 'json'
    refute_includes output.downcase, 'parse'
    refute_includes output.downcase, 'error'
  end
end
