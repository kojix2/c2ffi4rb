# frozen_string_literal: true

require 'json'

module C2FFI4RB
  class Parser
    TYPE_TABLE = {
      ':unsigned-int' => ':uint',
      ':unsigned-char' => ':uchar',
      ':unsigned-short' => ':ushort',
      ':long-long' => ':long_long',
      ':unsigned-long' => ':ulong',
      ':unsigned-long-long' => ':ulong_long',
      ':function-pointer' => ':pointer'
    }

    def self.parse(arr)
      new.parse(arr)
    end

    def initialize
      @struct_type = []
      @toplevels = []
      @anon_counter = 0
    end

    def parse(arr)
      arr.each { |form| process_toplevel(form) }
      puts @toplevels.join("\n\n")
    end

    private

    def process_toplevel(form)
      lines = \
        case form[:tag]
        when 'typedef'         then parse_typedef(form)
        when 'const'           then parse_const(form)
        when 'extern'          then parse_extern(form)
        when 'function'        then parse_function(form)
        when 'struct', 'union' then parse_struct_or_union(form)
        when 'enum'            then parse_enum(form)
        else
          raise "Unknown form: #{form[:tag]}"
        end

      @toplevels << lines
    end

    def parse_typedef(form)
      type = parse_type(form[:type])

      if @struct_type.include?(type)
        name = add_struct(form[:name])
        "#{name} = #{type}"
      else
        "typedef #{type}, :#{form[:name]}"
      end
    end

    def parse_const(form)
      type = parse_type(form[:type])
      if type == ':string'
        "#{form[:name].upcase} = \"#{form[:value]}\""
      else
        "#{form[:name].upcase} = #{form[:value]}"
      end
    end

    def parse_extern(form)
      'attach_variable ' \
          ":#{form[:name]}, :#{form[:name]}, #{parse_type(form[:type])}"
    end

    def parse_function(form)
      l = []
      l << "attach_function '#{form[:name]}', ["
      form[:parameters].each do |f|
        l << "  #{parse_type(f[:type])},"
      end
      l << "], #{parse_type(form['return-type'.intern])}"
      l.join("\n")
    end

    def parse_struct_or_union(form)
      make_struct(form)
    end

    def parse_enum(form)
      name = add_enum(form[:name])
      l = []
      l << "enum #{name}, ["
      form[:fields].each do |f|
        l << "  :#{f[:name]}, #{f[:value]},"
      end
      l << ']'
      l.join("\n")
    end

    def add_struct(name)
      # Anonymous structs are given a name
      if name == ''
        @anon_counter += 1
        name = "Anon_Type_#{@anon_counter}"
        return name
      end

      # Do not allow names that start with an underscore
      name = 'C' + name if name.start_with? '_'

      # Convert snake_case to CamelCase
      name.capitalize!
      name.gsub!(/_([a-z])/) { |m| "_#{m[1].upcase}" }

      @struct_type << name unless @struct_type.include? name
      name
    end

    def add_enum(name)
      # Anonymous enums are given a name
      if name == ''
        @anon_counter += 1
        name = ':anon_type_' + @anon_counter.to_s
        return name
      end

      # All enums are prefixed with a colon
      name = ":#{name}" unless name.start_with? ':'
      name
    end

    def make_struct(form)
      name = add_struct(form[:name])

      type = if form[:tag] == 'struct'
               'FFI::Struct'
             else
               'FFI::Union'
             end

      l = []
      l << "class #{name} < #{type}"

      if form[:fields].length.positive?
        l << '  layout \\'
        size = form[:fields].length
        anon_field_counter = 0
        form[:fields].each_with_index do |f, i|
          sep = i >= (size - 1) ? '' : ','
          field_name = f[:name]
          if field_name.empty?
            field_name = "anon_field_#{anon_field_counter}"
            anon_field_counter += 1
          end
          l << "    :#{field_name}, #{parse_type(f[:type])}#{sep}"
        end
      end
      l << 'end'
      l.join("\n")
    end

    def parse_type(form)
      tt = TYPE_TABLE[form[:tag]]
      return tt if tt

      case form[:tag]
      when ':pointer'          then parse_pointer_type(form)
      when ':array'            then parse_array_type(form)
      when ':struct', ':union' then add_struct(form[:name])
      when ':enum'             then add_enum(form[:name])
      when 'enum'              then parse_enum_type(form)
      when 'struct', 'union'   then parse_struct_or_union_type(form)
      else parse_default_type(form)
      end
    end

    def parse_pointer_type(form)
      pointee = parse_type(form[:type])
      if [':char', ':uchar'].include?(pointee)
        ':string'
      elsif @struct_type.include?(pointee)
        "#{pointee}.ptr"
      else
        ':pointer'
      end
    end

    def parse_array_type(form)
      "[#{parse_type(form[:type])}, #{form[:size]}]"
    end

    def parse_enum_type(form)
      form[:name] = add_enum(form[:name])
      process_toplevel(form)
      form[:name]
    end

    def parse_struct_or_union_type(form)
      form[:name] = add_struct(form[:name])
      process_toplevel(form)
      form[:name]
    end

    def parse_default_type(form)
      form[:tag].start_with?(':') ? form[:tag] : ":#{form[:tag]}"
    end
  end
end
