# frozen_string_literal: true

module C2FFI
  class Parser
    def self.parse(module_name, libs, arr, out = $stdout)
      Parser.new.parse(module_name, libs, arr, out)
    end

    def initialize
      @type_table = TYPE_TABLE.dup
      @struct_type = {}
      @toplevels = []
      @anon_counter = 0
    end

    def parse(module_name, libs, arr, out = $stdout)
      arr.each do |form|
        parse_toplevel(form)
      end

      out.puts "require 'ffi'"
      out.puts
      out.puts "module #{module_name}"
      out.puts '  extend FFI::Library'

      case libs
      when String
        out.puts "  ffi_lib \"#{libs}\""
      when Array
        out.puts "  ffi_lib #{libs.join(', ')}"
      end

      @toplevels.each do |t|
        out.puts
        case t
        when String
          out.puts "  #{t}"
        when Array
          t.each do |l|
            out.puts "  #{l}"
          end
        end
      end
      out.puts 'end'
    end

    private
    
    def parse_toplevel(form)
      case form[:tag]
      when 'typedef'
        type = parse_type(form[:type])

        # I don't think typedef works right with structs, so assign
        if @struct_type[type]
          name = add_struct(form[:name])
          s = format('%s = %s', name, type)
        else
          s = format('typedef %s, :%s', type, form[:name])
        end

      when 'const'
        type = parse_type(form[:type])
        s = format(type == ':string' ? '%s = "%s"' : '%s = %s',
                   form[:name].upcase, form[:value])
      when 'extern'
        s = format('attach_variable :%s, :%s, %s',
                   form[:name], form[:name],
                   parse_type(form[:type]))
      when 'function'
        s = []
        s << format("attach_function '%s', [", form[:name])
        form[:parameters].each do |f|
          s << "  #{parse_type(f[:type])},"
        end
        s << format('], %s', parse_type(form['return-type'.intern]))
        #                     emacs doesn't like :"foo" ---^

      when 'struct', 'union'
        name = add_struct(form[:name])
        s = make_struct(form)
      when 'enum'
        name = add_enum(form[:name])
        s = []
        s << format('enum %s, [', name)
        form[:fields].each do |f|
          s << format('  :%s, %s,',
                      f[:name], f[:value])
        end
        s << ']'
      end

      @toplevels << s if s
    end

    def add_struct(name)
      if name == ''
        @anon_counter += 1
        name = 'Anon_Type_' + @anon_counter.to_s
        return name
      end

      name = 'C' + name if name.start_with '_'

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
          s << format('    :%s, %s%s', f[:name], parse_type(f[:type]), sep)
        end
      end
      s << 'end'

      s
    end

    def parse_type(form)
      tt = @type_table[form[:tag]]
      return tt if tt

      case (form[:tag])
      when ':pointer'
        pointee = parse_type(form[:type])
        if [':char', ':uchar'].include?(pointee)
          return ':string'
        elsif @struct_type[pointee]
          return "#{@struct_type[pointee]}.ptr"
        else
          return ':pointer'
        end

      when ':array'
        return format('[%s, %d]',
                      parse_type(form[:type]),
                      form[:size])

      when ':struct', ':union'
        return add_struct(form[:name])
      when ':enum'
        return add_enum(form[:name])

      when 'enum'
        form[:name] = add_enum(form[:name])
        parse_toplevel(form)
        return form[:name]
      when 'struct', 'union'
        form[:name] = add_struct(form[:name])
        parse_toplevel(form)
        return form[:name]
      end

      # All non-Classy types are :-prefixed?
      if form[:tag][0] != ':'
        ":#{form[:tag]}"
      else
        form[:tag]
      end
    end
  end
end
