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

  attr_accessor :line, :binding, :result_prompt, :result, :options
  def initialize(options={})
    @options = OPTIONS.merge options
    @name, @binding, @line = @options.values_at(:name, :binding, :line)
    @irbrc = @options[:irbrc]
  end

  def loop
    before_loop
    catch(:ripl_exit) { while(true) do; loop_once; end }
    after_loop
  end

  def config; Ripl.config; end

  module API
    def before_loop
      Ripl::Runner.load_rc(@irbrc) if @irbrc
    end

    def loop_once
      @error_raised = nil
      @input = get_input
      throw(:ripl_exit) if !@input || @input == 'exit'
      eval_input(@input)
      print_result(@result)
    end

    def get_input
      print prompt
      $stdin.gets.chomp
    end

    def prompt
      @options[:prompt].respond_to?(:call) ? @options[:prompt].call : @options[:prompt]
    end

    def eval_input(input)
      @result = loop_eval(input)
      eval("_ = Ripl.shell.result", @binding)
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

    def print_result(result)
      puts(format_result(result)) unless @error_raised
    end

    def format_error(err); Ripl::Runner.format_error(err); end

    def format_result(result)
      @options[:result_prompt] + result.inspect
    end

    def after_loop; end
  end
  include API
end
