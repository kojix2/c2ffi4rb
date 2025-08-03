require_relative 'test_helper'

class EdgeCasesTest < Minitest::Test
  def setup
    @parser = C2FFI4RB::BindGen.new
  end

  # Test complex nested structures
  def test_deeply_nested_struct
    form = {
      tag: 'struct',
      name: 'NestedStruct',
      fields: [
        {
          name: 'inner',
          type: {
            tag: 'struct',
            name: 'InnerStruct',
            fields: [
              {
                name: 'value',
                type: { tag: ':int' }
              },
              {
                name: 'ptr',
                type: {
                  tag: ':pointer',
                  type: {
                    tag: 'struct',
                    name: 'DeepStruct',
                    fields: [
                      { name: 'deep_value', type: { tag: ':double' } }
                    ]
                  }
                }
              }
            ]
          }
        }
      ]
    }

    result = @parser.send(:create_struct_definition, form)
    assert_includes result, 'class NestedStruct < ::FFI::Struct'
    assert_includes result, ':inner, InnerStruct'
  end

  # Test function with array parameters
  def test_function_with_array_parameter
    form = {
      tag: 'function',
      name: 'process_array',
      parameters: [
        {
          name: 'arr',
          type: {
            tag: ':array',
            type: { tag: ':int' },
            size: 10
          }
        },
        {
          name: 'size',
          type: { tag: ':int' }
        }
      ],
      'return-type': { tag: ':void' }
    }

    result = @parser.send(:generate_function, form)
    assert_includes result, "attach_function 'process_array'"
    assert_includes result, ':pointer, # [:int, 10]'
    assert_includes result, ':int,'
    assert_includes result, '], :void'
  end

  # Test typedef redefinition
  def test_typedef_redefinition_warning
    # First typedef
    form1 = { tag: 'typedef', name: 'my_type', type: { tag: ':int' } }
    result1 = @parser.send(:generate_typedef, form1)
    assert_equal 'typedef :int, :my_type', result1

    # Same typedef - should be ignored
    form2 = { tag: 'typedef', name: 'my_type', type: { tag: ':int' } }
    result2 = @parser.send(:generate_typedef, form2)
    assert_includes result2, '# [c2ffi4rb] typedef already defined?'

    # Different typedef with same name - should warn
    form3 = { tag: 'typedef', name: 'my_type', type: { tag: ':long' } }
    result3 = @parser.send(:generate_typedef, form3)
    assert_equal 'typedef :long, :my_type', result3
  end

  # Test struct redefinition
  def test_struct_redefinition
    form = { tag: 'struct', name: 'TestStruct', fields: [] }

    # First definition
    result1 = @parser.send(:create_struct_definition, form)
    assert_includes result1, 'class TestStruct < ::FFI::Struct'

    # Second definition - should be ignored
    result2 = @parser.send(:create_struct_definition, form)
    assert_includes result2, '# [c2ffi4rb] Already defined: TestStruct'
  end

  # Test anonymous enum redefinition
  def test_anonymous_enum_redefinition
    form = {
      tag: 'enum',
      name: '',
      id: 123,
      fields: [{ name: 'VALUE', value: 1 }]
    }

    # First definition
    result1 = @parser.send(:generate_enum, form)
    assert_includes result1, 'enum :anon_enum_123'

    # Second definition - should be ignored
    result2 = @parser.send(:generate_enum, form)
    assert_includes result2, '# Already defined? anon_type_123'
  end

  # Test very long struct with many fields
  def test_struct_with_many_fields
    fields = (1..50).map do |i|
      {
        name: "field_#{i}",
        type: { tag: ':int' }
      }
    end

    form = {
      tag: 'struct',
      name: 'LargeStruct',
      fields: fields
    }

    result = @parser.send(:create_struct_definition, form)
    assert_includes result, 'class LargeStruct < ::FFI::Struct'
    assert_includes result, ':field_1, :int,'
    assert_includes result, ':field_50, :int' # Last field should not have comma
    refute_includes result.lines.last, ','
  end

  # Test struct with all anonymous fields
  def test_struct_with_all_anonymous_fields
    form = {
      tag: 'struct',
      name: 'AnonymousFields',
      fields: [
        { name: '', type: { tag: ':int' } },
        { name: '', type: { tag: ':char' } },
        { name: '', type: { tag: ':double' } }
      ]
    }

    result = @parser.send(:create_struct_definition, form)
    assert_includes result, ':anon_field_0, :int,'
    assert_includes result, ':anon_field_1, :char,'
    assert_includes result, ':anon_field_2, :double'
  end

  # Test mixed anonymous and named fields
  def test_struct_with_mixed_fields
    form = {
      tag: 'struct',
      name: 'MixedFields',
      fields: [
        { name: 'named_field', type: { tag: ':int' } },
        { name: '', type: { tag: ':char' } },
        { name: 'another_named', type: { tag: ':double' } },
        { name: '', type: { tag: ':float' } }
      ]
    }

    result = @parser.send(:create_struct_definition, form)
    assert_includes result, ':named_field, :int,'
    assert_includes result, ':anon_field_0, :char,'
    assert_includes result, ':another_named, :double,'
    assert_includes result, ':anon_field_1, :float'
  end

  # Test pointer to struct that doesn't exist yet
  def test_forward_struct_reference
    form = {
      tag: ':pointer',
      type: {
        tag: ':struct',
        name: 'ForwardDeclaredStruct',
        id: 999
      }
    }

    result = @parser.send(:resolve_type, form)
    assert_includes result, '.ptr'
  end

  # Test circular struct references
  def test_circular_struct_reference
    # This tests the case where struct A has a pointer to struct B,
    # and struct B has a pointer to struct A
    form_a = {
      tag: 'struct',
      name: 'StructA',
      fields: [
        {
          name: 'ptr_to_b',
          type: {
            tag: ':pointer',
            type: { tag: ':struct', name: 'StructB', id: 2 }
          }
        }
      ]
    }

    result_a = @parser.send(:create_struct_definition, form_a)
    assert_includes result_a, 'class StructA < ::FFI::Struct'
    assert_includes result_a, ':ptr_to_b, StructB.ptr'
  end

  # Test enum with negative values
  def test_enum_with_negative_values
    form = {
      tag: 'enum',
      name: 'SignedEnum',
      id: 1,
      fields: [
        { name: 'NEGATIVE', value: -1 },
        { name: 'ZERO', value: 0 },
        { name: 'POSITIVE', value: 1 }
      ]
    }

    result = @parser.send(:generate_enum, form)
    assert_includes result, ':NEGATIVE, -1,'
    assert_includes result, ':ZERO, 0,'
    assert_includes result, ':POSITIVE, 1,'
  end

  # Test very large enum values
  def test_enum_with_large_values
    form = {
      tag: 'enum',
      name: 'LargeEnum',
      id: 1,
      fields: [
        { name: 'SMALL', value: 1 },
        { name: 'LARGE', value: 2_147_483_647 }, # INT_MAX
        { name: 'VERY_LARGE', value: 4_294_967_295 } # UINT_MAX
      ]
    }

    result = @parser.send(:generate_enum, form)
    assert_includes result, ':SMALL, 1,'
    assert_includes result, ':LARGE, 2147483647,'
    assert_includes result, ':VERY_LARGE, 4294967295,'
  end

  # Test function with no parameters
  def test_function_with_no_parameters
    form = {
      tag: 'function',
      name: 'no_params',
      parameters: [],
      'return-type': { tag: ':int' }
    }

    result = @parser.send(:generate_function, form)
    assert_includes result, "attach_function 'no_params'"
    assert_includes result, '], :int'
  end

  # Test function with variadic parameters (if supported)
  def test_function_variadic
    form = {
      tag: 'function',
      name: 'printf_like',
      parameters: [
        { name: 'format', type: { tag: ':pointer', type: { tag: ':char' } } }
      ],
      'return-type': { tag: ':int' },
      variadic: true
    }

    result = @parser.send(:generate_function, form)
    assert_includes result, "attach_function 'printf_like'"
    assert_includes result, ':string,'
    assert_includes result, '], :int'
  end

  # Test constant with special characters in name
  def test_const_with_special_name
    form = {
      tag: 'const',
      name: '__SPECIAL_CONST__',
      type: { tag: ':int' },
      value: 42
    }

    result = @parser.send(:generate_const, form)
    assert_equal '__SPECIAL_CONST__ = 42', result
  end

  # Test typedef with complex pointer chain
  def test_typedef_complex_pointer_chain
    form = {
      tag: 'typedef',
      name: 'complex_ptr',
      type: {
        tag: ':pointer',
        type: {
          tag: ':pointer',
          type: {
            tag: ':pointer',
            type: { tag: ':char' }
          }
        }
      }
    }

    result = @parser.send(:generate_typedef, form)
    assert_equal 'typedef :pointer, :complex_ptr', result
  end
end
