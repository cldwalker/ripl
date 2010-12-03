module Ripl::Runner
  OPTIONS = [
    ['-f', 'Suppress loading ~/.irbrc'],
    ['-F', 'Suppress loading ~/.riplrc'],
    ['-d, --debug', "Set $DEBUG to true (same as `ruby -d')"],
    ['-I PATH', "Add to front of $LOAD_PATH. Delimit multiple paths with ':'"],
    ['-r, --require FILE', "Require file (same as `ruby -r')"],
    ['-v, --version', 'Print ripl version'],
    ['-h, --help', 'Print help']
  ]

  # Adds commandline options for --help
  def self.add_options(*options)
    OPTIONS.concat(options)
  end

  module API
    def run(argv=ARGV)
      argv[0].to_s[/^[^-]/] ? run_command(argv) : start(:argv=>argv)
    end

    def parse_options(argv)
      while argv[0] =~ /^-/
        case argv.shift
        when /-I=?(.*)/
          $LOAD_PATH.unshift(*($1.empty? ? argv.shift.to_s : $1).split(":"))
        when /-r=?(.*)/
          require $1.empty? ? argv.shift.to_s : $1
        when '-d'
          $DEBUG = true
        when '-v', '--version'
          puts Ripl::VERSION; exit
        when '-f'
          Ripl.config[:irbrc] = false
        when '-h', '--help'
          name_max = OPTIONS.map {|e| e[0].length }.max
          desc_max = OPTIONS.map {|e| e[1].length }.max
          puts "Usage: ripl [OPTIONS] [COMMAND] [ARGS]", "\nOptions:",
            OPTIONS.map {|k,v| "  %-*s  %-*s" % [name_max, k, desc_max, v] }
          exit
        when /^(--?[^-]+)/
          parse_option($1, argv)
        end
      end
    end

    def parse_option(option, argv)
      warn "ripl: invalid option `#{option.sub(/^-+/, '')}'"
    end

    def run_command(argv)
      exec "ripl-#{argv.shift}", *argv
    rescue Errno::ENOENT
      raise unless $!.message =~ /No such file or directory.*ripl-(\w+)/
      abort "`#{$1}' is not a ripl command."
    end

    def start(options={})
      argv = options.delete(:argv) || ARGV
      load_rc(Ripl.config[:riplrc]) unless argv.delete('-F')
      parse_options(argv)
      Ripl.shell(options).loop
    end

    def load_rc(file)
      load file if File.exists?(File.expand_path(file))
    rescue StandardError, SyntaxError
      warn "ripl: Error while loading #{file}:\n"+ format_error($!)
    end

    def format_error(err)
      "#{err.class}: #{err.message}\n    #{err.backtrace.join("\n    ")}"
    end
  end
  extend API
end
