# frozen_string_literal: true

require 'json'

module C2FFI4RB
  class BindGen
    DEFAULT_TYPE_TABLE = {
      ':signed-int' => ':int',
      ':unsigned-int' => ':uint',
      ':signed-char' => ':char',
      ':unsigned-char' => ':uchar',
      ':signed-short' => ':short',
      ':unsigned-short' => ':ushort',
      ':long-long' => ':long_long',
      ':ulong-long' => ':ulong_long',
      ':long-double' => ':long_double',
      ':signed-long' => ':long',
      ':unsigned-long' => ':ulong',
      ':unsigned-long-long' => ':ulong_long',
      ':function-pointer' => ':pointer'
    }

    # Class method to create instance and generate bindings
    def self.generate_bindings(arr)
      new.generate_bindings(arr)
    end

    # Initialize with optional type conversion table
    def initialize(type_table = {})
      @type_table = DEFAULT_TYPE_TABLE.merge(type_table)
      @struct_type = []
      @toplevels = []
      @anon_counter = 0
      @anon_enum_ids = []
      @typedefs = {}
    end

    # Main entry point: process all forms and output Ruby FFI code
    def generate_bindings(arr)
      arr.each { |form| process_toplevel(form) }
      puts @toplevels.join("\n\n")
    end

    private

    # Process a single top-level form and add to output
    def process_toplevel(form)
      lines = parse_form(form)
      @toplevels << lines
    end

    # Parse a form based on its tag and generate appropriate Ruby code
    def parse_form(form)
      validate_form(form)

      case form[:tag]
      when 'typedef'         then generate_typedef(form)
      when 'const'           then generate_const(form)
      when 'extern'          then generate_extern(form)
      when 'function'        then generate_function(form)
      when 'struct', 'union' then generate_struct_or_union(form)
      when 'enum'            then generate_enum(form)
      else
        raise ArgumentError,
              "Unknown form tag: '#{form[:tag]}'. Expected one of: typedef, const, extern, function, struct, union, enum"
      end
    rescue StandardError => e
      warn "Error processing form #{form.inspect}: #{e.message}"
      "# Error: #{e.message}"
    end

    # Validate form structure before processing
    def validate_form(form)
      raise ArgumentError, 'Form must be a Hash' unless form.is_a?(Hash)
      raise ArgumentError, 'Form must have a :tag key' unless form.key?(:tag)
      raise ArgumentError, 'Form :tag cannot be nil or empty' if form[:tag].nil? || form[:tag].empty?
    end

    # Generate typedef declaration, handling different typedef types
    def generate_typedef(form)
      type = resolve_type(form[:type])

      return handle_struct_typedef(form, type) if @struct_type.include?(type)
      return handle_self_referential_typedef(form[:name]) if type == ":{#{form[:name]}}"

      handle_regular_typedef(form, type)
    end

    # Handle typedef for struct types
    def handle_struct_typedef(form, type)
      name = define_struct(form[:name])
      name == type ? "# #{name} = #{type}" : "#{name} = #{type}"
    end

    # Handle self-referential typedef (ignore with warning)
    def handle_self_referential_typedef(name)
      warn "Ignoring self-referential typedef #{name}"
      "# Ignoring self-referential typedef #{name}"
    end

    # Handle regular typedef declarations
    def handle_regular_typedef(form, type)
      name = form[:name]

      if @typedefs.key?(name)
        return "# typedef already defined? #{name}" if @typedefs[name] == type

        warn "# Redefinition of #{name} from #{@typedefs[name]} to #{type}"
      end

      @typedefs[name] = type

      if form[:type][:tag] == ':array'
        "typedef :pointer, :#{name} # #{type}"
      else
        "typedef #{type}, :#{name}"
      end
    end

    # Generate constant definition
    def generate_const(form)
      type = resolve_type(form[:type])
      value = type == ':string' ? "\"#{form[:value]}\"" : form[:value]
      "#{form[:name].upcase} = #{value}"
    end

    # Generate external variable attachment
    def generate_extern(form)
      "attach_variable :#{form[:name]}, :#{form[:name]}, #{resolve_type(form[:type])}"
    end

    # Generate function attachment with parameters
    def generate_function(form)
      params = form[:parameters].map do |f|
        f[:type][:tag] == ':array' ? "  :pointer, # #{resolve_type(f[:type])}" : "  #{resolve_type(f[:type])},"
      end.join("\n")
      <<~FUNCTION
        attach_function '#{form[:name]}', [
        #{params}
        ], #{resolve_type(form[:'return-type'])}
      FUNCTION
    end

    # Generate struct or union definition
    def generate_struct_or_union(form)
      create_struct_definition(form)
    end

    # Generate enum definition with fields
    def generate_enum(form)
      id = form[:id]
      if form[:name].empty?
        return "# Already defined? anon_type_#{id}" if @anon_enum_ids.include?(id)

        @anon_enum_ids << id
      end
      name = normalize_enum_name(form[:name], form[:id])
      fields = form[:fields].map { |f| "  :#{f[:name]}, #{f[:value]}," }.join("\n")
      <<~ENUM
        enum #{name}, [
        #{fields}
        ]
      ENUM
    end

    # Normalize struct name: handle anonymous structs and convert to CamelCase
    def normalize_struct_name(name)
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

      name
    end

    # Register struct name to avoid redefinition
    def register_struct(name)
      if @struct_type.include? name
        false
      else
        @struct_type << name
      end
    end

    # Normalize enum name: handle anonymous enums and add colon prefix
    def normalize_enum_name(name, id)
      # Anonymous enums are given a name
      name = "anon_enum_#{id}" if name.empty?

      # All enums are prefixed with a colon
      name = ":#{name}" unless name.start_with?(':')
      name
    end

    # Define struct name and register it
    def define_struct(name)
      name = normalize_struct_name(name)
      register_struct(name)
      name
    end

    # Create complete struct/union definition with fields
    def create_struct_definition(form)
      name = normalize_struct_name(form[:name])
      return "# Already defined? #{name}" if @struct_type.include?(name)

      register_struct(name)

      lines = build_struct_class_definition(form, name)
      lines.join("\n")
    end

    # Build struct class definition with inheritance
    def build_struct_class_definition(form, name)
      type = form[:tag] == 'struct' ? '::FFI::Struct' : '::FFI::Union'
      lines = ["class #{name} < #{type}"]

      lines.concat(build_struct_layout(form[:fields])) if form[:fields].any?

      lines << 'end'
      lines
    end

    # Build layout definition for struct fields
    def build_struct_layout(fields)
      lines = ['  layout \\']
      anon_field_counter = 0

      fields.each_with_index do |field, index|
        field_name = field[:name].empty? ? "anon_field_#{anon_field_counter}" : field[:name]
        anon_field_counter += 1 if field[:name].empty?

        separator = index == fields.size - 1 ? '' : ','
        lines << "    :#{field_name}, #{resolve_type(field[:type])}#{separator}"
      end

      lines
    end

    # Resolve C type to Ruby FFI type
    def resolve_type(form)
      @type_table.fetch(form[:tag]) do
        case form[:tag]
        when ':pointer'          then resolve_pointer_type(form)
        when ':array'            then resolve_array_type(form)
        when ':struct', ':union' then define_struct(form[:name])
        when ':enum'             then normalize_enum_name(form[:name], form[:id])
        when 'struct', 'union'   then define_struct_or_union_type(form)
        when 'enum'              then normalize_enum_name_type(form)
        else resolve_default_type(form)
        end
      end
    end

    # Resolve pointer type: handle char* as string, struct pointers
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

    # Resolve array type to FFI array format
    def resolve_array_type(form)
      "[#{resolve_type(form[:type])}, #{form[:size]}]"
    end

    # Process enum type and return normalized name
    def normalize_enum_name_type(form)
      form[:name] = normalize_enum_name(form[:name], form[:id])
      process_toplevel(form)
      form[:name]
    end

    # Process struct/union type and return normalized name
    def define_struct_or_union_type(form)
      form[:name] = normalize_struct_name(form[:name])
      process_toplevel(form)
      form[:name]
    end

    # Resolve default/unknown types
    def resolve_default_type(form)
      st_name = normalize_struct_name(form[:tag])
      return st_name if @struct_type.include?(st_name)

      form[:tag].start_with?(':') ? form[:tag] : ":#{form[:tag]}"
    end
  end
end
