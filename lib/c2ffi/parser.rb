# frozen_string_literal: true

module C2FFI
  class Parser
    TYPE_TABLE = {
      "unsigned-int": :uint,
      "unsigned-char": :uchar,
      "unsigned-long": :ulong,
      "function-pointer": :pointer
    }.freeze

    def self.parse(arr)
      Parser.new.parse(arr)
    end

    def initialize
      @struct_type = {}
      @toplevels = []
      @anon_counter = 0
    end

    def parse(arr)
      arr.each do |form|
        s = parse_toplevel(form)
        @toplevels << s if s
      end

      @toplevels.each do |t|
        puts
        case t
        when String
          puts "#{t}"
        when Array
          t.each do |l|
            puts "#{l}"
          end
        end
      end
    end

    private

    def parse_toplevel(form)
      case form[:tag]
      when 'typedef'
        type = parse_type(form[:type])

        # I don't think typedef works right with structs, so assign
        if @struct_type[type]
          name = add_struct(form[:name])
          "#{name} = #{type}"
        else
          "typedef #{type}, :#{form[:name]}"
        end

      when 'const'
        type = parse_type(form[:type])
        if type == ':string'
          "#{form[:name].upcase} = \"#{form[:value]}\""
        else
          "#{form[:name].upcase} = #{form[:value]}"
        end

      when 'extern'
        'attach_variable ' \
            ":#{form[:name]}, :#{form[:name]}, #{parse_type(form[:type])}"

      when 'function'
        s = []
        s << "attach_function '#{form[:name]}', ["
        form[:parameters].each do |f|
          s << "  #{parse_type(f[:type])},"
        end
        s << "], #{parse_type(form['return-type'.intern])}"
      # emacs doesn't like :"foo" ---^

      when 'struct', 'union'
        name = add_struct(form[:name])
        make_struct(form)

      when 'enum'
        name = add_enum(form[:name])
        s = []
        s << "enum #{name}, ["
        form[:fields].each do |f|
          s << "  :#{f[:name]}, #{f[:value]},"
        end
        s << ']'
      end
    end

    def add_struct(name)
      if name == ''
        @anon_counter += 1
        name = 'Anon_Type_' + @anon_counter.to_s
        return name
      end

      name = 'C' + name if name.start_with? '_'

      name = name.capitalize.gsub!(/_([a-z])/) { |m| "_#{m[1].upcase}" }
      @struct_type[name] = true
      name
    end

    def add_enum(name)
      if name == ''
        @anon_counter += 1
        name = ':anon_type_' + @anon_counter.to_s
        return name
      end

      if name[0] != ':'
        ":#{name}"
      else
        name
      end
    end

    def make_struct(form)
      name = add_struct(form[:name])

      type = if form[:tag] == ':struct'
               'FFI::Struct'
             else
               'FFI::Union'
             end

      s = []
      s << "class #{name} < #{type}"

      if form[:fields].length.positive?
        s << '  layout \\'
        size = form[:fields].length
        sep = ','
        form[:fields].each_with_index do |f, i|
          sep = '' if i >= (size - 1)
          s << "    :#{f[:name]}, #{parse_type(f[:type])}#{sep}"
        end
      end
      s << 'end'
    end

    def parse_type(form)
      tt = TYPE_TABLE[form[:tag]]
      return tt if tt

      case form[:tag]
      when ':pointer'
        pointee = parse_type(form[:type])
        if [':char', ':uchar'].include?(pointee)
          ':string'
        elsif @struct_type[pointee]
          "#{@struct_type[pointee]}.ptr"
        else
          ':pointer'
        end

      when ':array'
        "[#{parse_type(form[:type])}, #{form[:size]}]"

      when ':struct', ':union'
        add_struct(form[:name])

      when ':enum'
        add_enum(form[:name])

      when 'enum'
        form[:name] = add_enum(form[:name])
        parse_toplevel(form)
        form[:name]

      when 'struct', 'union'
        form[:name] = add_struct(form[:name])
        parse_toplevel(form)
        form[:name]

      else
        # All non-Classy types are :-prefixed?
        if form[:tag][0] != ':'
          ":#{form[:tag]}"
        else
          form[:tag]
        end
      end
    end
  end
end
