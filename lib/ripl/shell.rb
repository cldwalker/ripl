class Ripl::Shell
  OPTIONS = {:name=>'ripl', :line=>1, :result_prompt=>'=> ', :prompt=>'>> ',
    :binding=>TOPLEVEL_BINDING, :irbrc=>'~/.irbrc'}

  def self.create(options={})
    require 'ripl/readline' if options[:readline]
    require 'ripl/completion'
    new(options)
  rescue LoadError
    new(options)
  end

  attr_accessor :line, :binding, :result_prompt, :last_result, :options
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

  module API
    def before_loop
      Ripl::Runner.load_rc(@irbrc) if @irbrc
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
      print prompt
      $stdin.gets.chomp
    end

    def prompt
      @options[:prompt].respond_to?(:call) ? @options[:prompt].call : @options[:prompt]
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

    def format_error(err); Ripl::Runner.format_error(err); end

    def format_result(result)
      @options[:result_prompt] + result.inspect
    end

    def after_loop; end
  end
  include API
end
