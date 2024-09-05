# frozen_string_literal: true

require 'json'

module C2FFI4RB
  class BindGen
    TYPE_TABLE = {
      ':unsigned-int' => ':uint',
      ':unsigned-char' => ':uchar',
      ':unsigned-short' => ':ushort',
      ':long-long' => ':long_long',
      ':unsigned-long' => ':ulong',
      ':unsigned-long-long' => ':ulong_long',
      ':function-pointer' => ':pointer'
    }.freeze

    def self.generate_bindings(arr)
      new.generate_bindings(arr)
    end

    def initialize
      @struct_type = []
      @toplevels = []
      @anon_counter = 0
    end

    def generate_bindings(arr)
      arr.each { |form| process_toplevel(form) }
      puts @toplevels.join("\n\n")
    end

    private

    def process_toplevel(form)
      lines = parse_form(form)
      @toplevels << lines
    end

    def parse_form(form)
      case form[:tag]
      when 'typedef'         then generate_typedef(form)
      when 'const'           then generate_const(form)
      when 'extern'          then generate_extern(form)
      when 'function'        then generate_function(form)
      when 'struct', 'union' then generate_struct_or_union(form)
      when 'enum'            then generate_enum(form)
      else
        raise "Unknown form: #{form[:tag]}"
      end
    end

    def generate_typedef(form)
      type = resolve_type(form[:type])
      if @struct_type.include?(type)
        name = define_struct(form[:name])
        "#{name} = #{type}"
      else
        "typedef #{type}, :#{form[:name]}"
      end
    end

    def generate_const(form)
      type = resolve_type(form[:type])
      value = type == ':string' ? "\"#{form[:value]}\"" : form[:value]
      "#{form[:name].upcase} = #{value}"
    end

    def generate_extern(form)
      "attach_variable :#{form[:name]}, :#{form[:name]}, #{resolve_type(form[:type])}"
    end

    def generate_function(form)
      params = form[:parameters].map { |f| "  #{resolve_type(f[:type])}," }.join("\n")
      <<~FUNCTION
        attach_function '#{form[:name]}', [
        #{params}
        ], #{resolve_type(form[:'return-type'])}
      FUNCTION
    end

    def generate_struct_or_union(form)
      create_struct_definition(form)
    end

    def generate_enum(form)
      name = normalize_enum_name(form[:name])
      fields = form[:fields].map { |f| "  :#{f[:name]}, #{f[:value]}," }.join("\n")
      <<~ENUM
        enum #{name}, [
        #{fields}
        ]
      ENUM
    end

    def define_struct(name)
      # Anonymous structs are given a name
      if name.empty?
        @anon_counter += 1
        name = "Anon_Type_#{@anon_counter}"
        return name
      end

      # Do not allow names that start with an underscore
      name = 'C' + name if name.start_with?('_')

      # Convert snake_case to CamelCase
      name = name[0].upcase + name[1..-1]

      name.gsub!(/_([a-z])/) { |m| "#{m[1].upcase}" }

      @struct_type << name unless @struct_type.include? name
      name
    end

    def normalize_enum_name(name)
      # Anonymous enums are given a name
      if name.empty?
        @anon_counter += 1
        name = "anon_type_#{@anon_counter}"
      end

      # All enums are prefixed with a colon
      name = ":#{name}" unless name.start_with?(':')
      name
    end

    def create_struct_definition(form)
      name = define_struct(form[:name])
      type = form[:tag] == 'struct' ? 'FFI::Struct' : 'FFI::Union'

      lines = ["class #{name} < #{type}"]

      if form[:fields].any?
        lines << '  layout \\'
        anon_field_counter = 0

        form[:fields].each_with_index do |f, i|
          field_name = f[:name].empty? ? "anon_field_#{anon_field_counter}" : f[:name]
          anon_field_counter += 1 if f[:name].empty?

          sep = i == form[:fields].size - 1 ? '' : ','
          lines << "    :#{field_name}, #{resolve_type(f[:type])}#{sep}"
        end
      end

      lines << 'end'
      lines.join("\n")
    end

    def resolve_type(form)
      TYPE_TABLE.fetch(form[:tag]) do
        case form[:tag]
        when ':pointer'          then resolve_pointer_type(form)
        when ':array'            then resolve_array_type(form)
        when ':struct', ':union' then define_struct(form[:name])
        when ':enum'             then normalize_enum_name(form[:name])
        when 'struct', 'union'   then define_struct_or_union_type(form)
        when 'enum'              then normalize_enum_name_type(form)
        else resolve_default_type(form)
        end
      end
    end

    def resolve_pointer_type(form)
      pointee = resolve_type(form[:type])
      if [':char', ':uchar'].include?(pointee)
        ':string'
      elsif @struct_type.include?(pointee)
        "#{pointee}.ptr"
      else
        ':pointer'
      end
    end

    def resolve_array_type(form)
      "[#{resolve_type(form[:type])}, #{form[:size]}]"
    end

    def normalize_enum_name_type(form)
      form[:name] = normalize_enum_name(form[:name])
      process_toplevel(form)
      form[:name]
    end

    def define_struct_or_union_type(form)
      form[:name] = define_struct(form[:name])
      process_toplevel(form)
      form[:name]
    end

    def resolve_default_type(form)
      form[:tag].start_with?(':') ? form[:tag] : ":#{form[:tag]}"
    end
  end
end
