require 'bacon'
require 'bacon/bits'
require 'rr'
require 'bacon/rr'
require 'stringio'

ENV['RIPL_HISTORY'] = File.dirname(__FILE__) + '/.irb_history'
ENV['RIPL_RC'] = File.dirname(__FILE__) + '/.riplrc'
require 'ripl'
include Ripl

module Helpers
  def ripl(*args)
    options = args[-1].is_a?(Hash) ? args.pop : {}
    mock_riplrc unless options[:riplrc] == false
    mock(Ripl.shell).loop unless options[:loop] == false
    capture_stdout { Ripl::Runner.run(args) }
  end

  def mock_riplrc(&block)
    mock(Runner).load_rc(Ripl.config[:riplrc], &block)
  end

  def mock_shell(&block)
    mock(Shell).create(anything) {|e|
      shell = Shell.new(e)
      block ? block.call(shell) : mock(shell).loop
      shell
    }
  end

  def reset_ripl
    Ripl.instance_eval "@config = @shell = @riplrc = nil"
  end

  def reset_shell
    Ripl.send(:remove_const, :Shell)
    $".delete $".grep(/shell\.rb/)[0]
    require 'ripl/shell'
    Ripl::Shell.include Ripl::History
  end

  def reset_config
    Ripl.config.merge! :history => '~/.irb_history', :completion => {}
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end
end

Bacon::Context.send :include, Helpers
