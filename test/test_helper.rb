require 'bacon'
require 'bacon/bits'
require 'rr'
require 'bacon/rr'
require 'stringio'
require 'ripl'
include Ripl

module Helpers
  def ripl(*args)
    options = args[-1].is_a?(Hash) ? args.pop : {}
    mock_riplrc unless options[:riplrc] == false
    mock(Runner).start if options[:start]
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
    Ripl.instance_eval "@shell = @riplrc = nil"
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
