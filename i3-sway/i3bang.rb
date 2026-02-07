#!/usr/bin/env ruby

class I3bangError < RuntimeError; end

def i3bang config, header = ''
    nobracket = config.include? '#!nobracket'

    if File.exist?(File.expand_path('~/.config/sway'))
      config.gsub! /\s*#*#[! ](?!sway config).*\n/, "\n"
    elsif File.exist?(File.expand_path('~/.config/i3'))
      config.gsub! /\s*#*#[! ](?!i3 config).*\n/, "\n"
    end
    config.gsub! /\s+$/, ''
    config.gsub! /\\\n\s*/, ''
    config += "\n"
    config = header + config

    def expand_nobracket config
        placeholder = '__PLCHLD__'
        ph_arr = []
        n = -1
        config.gsub!(/(?:!\?<|!@<+)[\s\S]*?\n>(?=\n)|!@<[^>+][^>]*>|!!?<[^>]*>/x) {|m|
            n += 1
            if m[1] == '@'
                m = m[3..-2]
                expand = false
                if m[0] == '+'
                    expand = true
                    m = m[1..-1]
                end
                expand_nobracket m if expand
                m = '!@<' + m + '>'
            end
            ph_arr.push m
            placeholder + "<#{n}>"
        }
        config.gsub!(/^\s*(![@!?]?)([^!\n]*)$/x, '\1<\2>')
        config.gsub!(/(![@!?]?)([^<@!?\s]\S*)/x, '\1<\2>')
        config.gsub!(/#{placeholder}<(\d+)>/) { ph_arr[$1.to_i] }
    end

    expand_nobracket config if nobracket

    config.gsub!(/!\?<([\s\S]*?\n)>(?=\n)/) {
        condition, data = $1.split "\n", 2
        raise I3bangError, 'insufficient argumets for conditional' if condition.nil? || data.nil?
        raise I3bangError, "malformed condition #{condition}" unless condition.index '='
        var, val = condition.split '=', 2
        ENV[var] == val ? data : ''
    }

    i3bang_sections = Hash.new {|_, x| raise I3bangError, "unknown section #{x}" }
    config.gsub!(/!@<+([\s\S]*?\n)>(?=\n)|!@<([^>+][^>]*)>/) {
        sec = $1 || $2
        if sec.include? "\n"
            name, data = sec.split "\n", 2
            noecho = false
            if name[0] == '*'
                noecho = true
                name = name[1..-1]
            end
            i3bang_sections[name] = data
            noecho ? '' : data
        else
            i3bang_sections[sec]
        end
    }

    exrgx = /!!<([^>]*)>/
    while config =~ exrgx
        config.sub!(/^.*#{exrgx}.*$/) {|line|
            expansions = line.scan(exrgx).map{|expansion|
                group, values = expansion[0].split('!', 2)
                if values.nil?
                    values = group
                    group = "__default_group"
                end
                [group, values.gsub(/(\d+)\.\.(\d+)/) {
                    [*$1.to_i..$2.to_i] * ?,
                }.split(?,, -1)]
            }
            group = expansions[0][0]
            maxlen = expansions.select{|g, _| g == group}.map(&:last).map(&:size).max
            expansions.map! {|g, values|
                g == group ?
                    [g, (values * (maxlen * 1.0 / values.length).ceil)[0...maxlen]] :
                    [g, values]
            }
            Array.new(expansions[0][1].length) { line.clone }.map {|l|
                idx = -1
                l.gsub(exrgx) {|m|
                    idx += 1
                    expansions[idx][0] == group ? expansions[idx][1].shift : m
                }
            }.join "\n"
        }
        expand_nobracket config if nobracket
    end

    config.gsub! /\\\n\s*/, ''

    i3bang_vars = Hash.new {|_, k| (k.is_a? Symbol) ? raise(I3bangError, "unknown variable #{k}") : k }

    config.gsub!(/(?<!!)!<([^>]*)>/) {
        s = $1
        prec = Hash.new {|_, x| (x.nil? || '()'.include?(x)) ? -1 : raise(I3bangError, "unknown operator #{x}") }
        prec.merge!({'=' => 0, '+' => 1, '-' => 1, '*' => 2, '/' => 2, '%' => 2, '**' => 3})
        rpn = []
        opstack = []
        tokens = s.gsub(/\s/, '').scan(/\w[\w\d]*|\d+(?:\.\d+)?|\*\*|./)

        op = nil
        tokens.each do |t|
            case t[0]
            when 'a'..'z', 'A'..'Z', '_' then rpn.push t.to_sym
            when '0'..'9' then rpn.push t.to_i
            when '(' then opstack.push t
            when ')'
                while (op = opstack.pop) != '('
                    raise I3bangError, 'mismatched parens' if op.nil?
                    rpn.push op
                end
            else
                rpn.push opstack.pop while prec[t] <= prec[opstack[-1]]
                opstack.push t
            end
        end
        rpn.push op while (op = opstack.pop)

        stack = []
        rpn.each do |t|
            case t
            when Integer, Symbol # FIXED: Fixnum -> Integer
                stack.push t
            when '='
                b, a = stack.pop, stack.pop
                raise I3bangError, "not enough operands" if a.nil? || b.nil?
                i3bang_vars[a] = i3bang_vars[b]
            else
                b, a = stack.pop, stack.pop
                raise I3bangError, "not enough operands" if a.nil? || b.nil?
                stack.push (case t
                            when '+' then ->a, b { a + b }
                            when '-' then ->a, b { a - b }
                            when '*' then ->a, b { a * b }
                            when '/' then ->a, b { a / b }
                            when '%' then ->a, b { a % b }
                            when '**' then ->a, b { a ** b }
                            when '(' then raise I3bangError, 'mismatched parens'
                           end)[i3bang_vars[a], i3bang_vars[b]]
            end
        end
        i3bang_vars[stack[0]]
    }

    config.gsub! /\n+/, "\n"
    config.sub! /\A\n/, ''
    config
end

if __FILE__ == $0
    if File.exist?(File.expand_path('~/.config/sway'))
        INFILE = File.expand_path('~/.config/sway/_config')
        OUTFILE = File.expand_path('~/.config/sway/config')
    elsif File.exist?(File.expand_path('~/.config/i3'))
        INFILE = File.expand_path('~/.config/i3/_config')
        OUTFILE = File.expand_path('~/.config/i3/config')
    end

    begin
        config = File.read INFILE
        output = i3bang(config, "##########\n# Generated via i3bang\n##########\n")
        File.write(OUTFILE, output)
    rescue StandardError => e
        # Log to STDERR so Emacs can see it, then exit with error code
        STDERR.puts "[ERROR] #{e.message}"
        STDERR.puts e.backtrace
        exit 1
    end
end
