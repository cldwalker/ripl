module Ripl::Runner
  def self.included(mod)
    mod.extend(self)
  end

  module API
    def run
      load_rc(Ripl.config[:riplrc])
      @riplrc = true
      parse_options(ARGV)
      ARGV[0] ? run_command(ARGV) : start
    end

    def parse_options(argv)
      while argv[0] =~ /^-/
        case argv.shift
        when /-I=?(.*)/
          $LOAD_PATH.unshift(*$1.split(":"))
        when /-r=?(.*)/
          require $1
        when '-d'
          $DEBUG = true
        when '-v', '--version'
          puts Ripl::VERSION; exit
        when '-f'
          ENV['RIPL_IRBRC'] = 'false'
        when '-h', '--help'
          puts IO.readlines(__FILE__).grep(/^#/).map {|e| e.sub(/^#\s/,'') }; exit
        end
      end
    end

    def run_command(argv)
      exec "ripl-#{argv.shift}", *argv
    rescue Errno::ENOENT
      raise unless $!.message =~ /No such file or directory.*ripl-(\w+)/
      abort "`#{$1}' is not a ripl command."
    end

    def start(options={})
      load_rc(Ripl.config[:riplrc]) unless @riplrc
      Ripl.config[:irbrc] = ENV['RIPL_IRBRC'] != 'false' if ENV['RIPL_IRBRC']
      Ripl.shell(options).loop
    end

    def load_rc(file)
      load file if File.exists?(File.expand_path(file))
    rescue StandardError, SyntaxError
      warn "Error while loading #{file}:\n"+ format_error($!)
    end

    def format_error(err)
      "#{err.class}: #{err.message}\n    #{err.backtrace.join("\n    ")}"
    end
  end
  extend API
end
__END__
# Usage: ripl [OPTIONS] [COMMAND] [ARGS]
#
# Options:
#   -f                  Supress loading ~/.irbrc
#   -d, --debug         Set $DEBUG to true (same as `ruby -d')
#   -I=PATH             Add to front of $LOAD_PATH. Delimit multiple paths with ':'
#   -r, --require=FILE  Require file (same as `ruby -r')
#   -v, --version       Print ripl version
#   -h, --help          Print help
