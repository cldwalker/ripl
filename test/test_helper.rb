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
    mock(Runner).load_rc(Ripl.config[:riplrc])
    mock(Runner).start if options[:start]
    capture_stdout { Ripl::Runner.run(args) }
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
end

Bacon::Context.send :include, Helpers
