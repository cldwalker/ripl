class Ripl::Runner
  OPTIONS = [
    ['-f', 'Suppress loading ~/.irbrc'],
    ['-F', 'Suppress loading ~/.riplrc'],
    ['-d, --debug', "Set $DEBUG to true (same as `ruby -d')"],
    ['-I PATH', "Add to front of $LOAD_PATH. Delimit multiple paths with ':'"],
    ['-r, --require FILE', "Require file (same as `ruby -r')"],
    ['-v, --version', 'Print version'],
    ['-h, --help', 'Print help']
  ]
  class <<self; attr_accessor :argv, :app; end
  self.app = 'ripl'

  # Adds commandline options for --help
  def self.add_options(*options)
    OPTIONS.concat(options)
  end

  def self.run(argv=ARGV)
    argv[0].to_s[/^[^-]/] ? run_command(argv) : start(:argv => argv)
  end

  def self.run_command(argv)
    exec "#{app}-#{argv.shift}", *argv
  rescue Errno::ENOENT
    raise unless $!.message =~ /No such file or directory.*#{app}-(\w+)/
    abort "`#{$1}' is not a #{app} command."
  end

  def self.start(options={})
    @argv = options.delete(:argv) || ARGV
    argv = @argv.dup
    load_rc(Ripl.config[:riplrc]) unless argv.delete('-F') || options[:riplrc] == false
    argv.each {|e| e[/^-/] ? break : argv.shift } if $0[/#{app}-\w+$/]
    parse_options(argv) if $0[/#{app}$|#{app}-\w+$/]
    Ripl.shell(options).loop
  end

  def self.load_rc(file)
    load file if File.exists?(File.expand_path(file))
  rescue StandardError, SyntaxError, LoadError
    warn "#{app}: Error while loading #{file}:\n"+ format_error($!)
  end

  module API
    def parse_options(argv)
      while argv[0] =~ /^-/
        case argv.shift
        when /-I=?(.*)/
          $LOAD_PATH.unshift(*($1.empty? ? argv.shift.to_s : $1).split(":"))
        when /-r=?(.*)/        then require($1.empty? ? argv.shift.to_s : $1)
        when '-d'              then $DEBUG = true
        when '-v', '--version' then puts(Ripl::VERSION); exit
        when '-f'              then Ripl.config[:irbrc] = false
        when '-h', '--help'    then puts(help); exit
        when /^(--?[^-]+)/     then parse_option($1, argv)
        end
      end
    end

    def help
      return("#{app} #{$1} [ARGS] [OPTIONS]") if $0[/#{app}-(\w+)/]
      name_max = OPTIONS.map {|e| e[0].length }.max
      desc_max = OPTIONS.map {|e| e[1].length }.max
      ["Usage: #{app} [COMMAND] [ARGS] [OPTIONS]", "\nOptions:",
        OPTIONS.map {|k,v| "  %-*s  %-*s" % [name_max, k, desc_max, v] }]
    end

    def parse_option(option, argv)
      warn "#{app}: invalid option `#{option.sub(/^-+/, '')}'"
    end

    def format_error(err)
      "#{err.class}: #{err.message}\n    #{err.backtrace.join("\n    ")}"
    end
  end
  extend API
end
