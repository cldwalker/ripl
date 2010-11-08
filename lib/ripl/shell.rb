module Ripl
  class Shell
    OPTIONS = {:name=>'ripl', :line=>1, :result_prompt=>'=> ', :prompt=>'>> ',
      :binding=>TOPLEVEL_BINDING, :irbrc=>'~/.irbrc'}

    def self.create(options={})
      load_rc(Ripl.config[:riplrc])
      options = Ripl.config.merge options
      require 'ripl/readline' if options[:readline]
      require 'ripl/completion'
      Shell.new(options)
    rescue LoadError
      Shell.new(options)
    end

    def self.load_rc(file)
      load file if File.exists?(File.expand_path(file))
    rescue StandardError, SyntaxError
      warn "Error while loading #{file}:\n"+ format_error($!)
    end

    def self.format_error(err)
      "#{err.class}: #{err.message}\n    #{err.backtrace.join("\n    ")}"
    end

    attr_accessor :line, :binding, :result_prompt, :last_result
    def initialize(options={})
      @options = OPTIONS.merge options
      @name, @binding, @line = @options.values_at(:name, :binding, :line)
      @irbrc = @options[:irbrc]
    end

    def loop
      before_loop
      during_loop
      after_loop
    end

    def config; Ripl.config; end
  end

  module Pluggable
    def before_loop
      Shell.load_rc(@irbrc) if @irbrc
    end

    def during_loop
      while true do
        @error_raised = nil
        input = get_input
        break if !input || input == 'exit'
        loop_once(input)
        puts(format_result(@last_result)) unless @error_raised
      end
    end

    def get_input
      print @options[:prompt]
      $stdin.gets.chomp
    end

    def loop_once(input)
      @last_result = loop_eval(input)
      eval("_ = Ripl.shell.last_result", @binding)
    rescue Exception => e
      @error_raised = true
      print_eval_error(e)
    ensure
      @line += 1
    end

    def loop_eval(str)
      eval(str, @binding, "(#{@name})", @line)
    end

    def print_eval_error(err)
      warn format_error(err)
    end

    def format_error(err); Shell.format_error(err); end

    def format_result(result)
      @options[:result_prompt] + result.inspect
    end

    def after_loop; end
  end
  Shell.send :include, Pluggable
end
