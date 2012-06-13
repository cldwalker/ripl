require File.join(File.dirname(__FILE__), 'test_helper')
require 'fileutils'

HISTORY_FILE = File.dirname(__FILE__) + '/ripl_history'

describe "History with readline" do
  def shell
    Ripl.shell(:history => HISTORY_FILE, :readline => false, :completion => false)
  end

  def history_must_equal(history, sh=shell)
    stub(Ripl::Runner).load_rc
    sh.before_loop
    sh.history.to_a.should == history
  end

  before_all { reset_shell }
  before do
    reset_ripl
    if defined? Readline
      1.upto(Readline::HISTORY.size) { Readline::HISTORY.shift }
    end
  end
  after { FileUtils.rm_f HISTORY_FILE }

  it "#after_loop saves history" do
    inputs = %w[blih blah]
    shell.instance_variable_set '@history', inputs
    shell.after_loop
    File.read(HISTORY_FILE).should == inputs.join($/) + $/
  end

  it "#before_loop loads previous history" do
    File.open(HISTORY_FILE, 'w') {|f| f.write %w[check the mike].join($/) }
    history_must_equal %w{check the mike}
  end

  it "#before_loop loads previous history only when it's empty" do
    File.open(HISTORY_FILE, 'w') {|f| f.write %w[check the mike].join($/) }
    history = %w[already there]
    shell.instance_variable_set(:@history, history.dup)
    history_must_equal history
  end

  it "#before_loop has empty history if no history file exists" do
    history_must_equal []
  end

  it "#get_input adds to history" do
    mock($stdin).gets { 'blarg' }
    capture_stdout { shell.get_input }
    shell.history.should == ['blarg']
  end

  it "#read_history is accessible to plugins in #before_loop" do
    mod = Object.const_set "Ping_read_history", Module.new
    mod.send(:define_method, 'read_history') { @history = ['pong_read_history'] }
    Shell.send :include, mod
    history_must_equal ['pong_read_history']
  end

  it "#write_history is accessible to plugins in #after_loop" do
    mod = Object.const_set "Ping_write_history", Module.new
    mod.send(:define_method, 'write_history') { @history = ['pong_write_history'] }
    Shell.send :include, mod
    shell.after_loop
    shell.history.should == ['pong_write_history']
  end

  it "#history is overridable in #write_history when readline is enabled" do
    SandboxShell = Shell.dup
    mock(Shell).include(is_a(Module)) {} # try to avoid side-effect...
    require 'ripl/readline'
    SandboxShell.send :include, Ripl::Readline
    sandbox_shell = SandboxShell.create(:readline => true)

    mod = Module.new { def write_history() @history = ['updated_history']  end }
    SandboxShell.send :include, mod

    sandbox_shell.after_loop
    sandbox_shell.history.should == ['updated_history']
  end

  describe "with no history_file" do
    def shell
      Ripl.shell(:history => false)
    end

    before_all do
      FileUtils.touch(HISTORY_FILE)
      reset_shell
    end

    it "#after_loop does not save history" do
      inputs = %w{blih blah}
      shell.instance_variable_set '@history', inputs
      shell.after_loop
      File.read(HISTORY_FILE).should == ''
    end

    it "#before_loop does not load history" do
      File.open(HISTORY_FILE, 'w') {|f| f.puts 'check', 'the', 'mike' }
      history_must_equal [], shell
    end
  end
end
