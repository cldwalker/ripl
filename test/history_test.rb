require File.join(File.dirname(__FILE__), 'test_helper')
require 'fileutils'

HISTORY_FILE = File.dirname(__FILE__) + '/ripl_history'

describe "History" do
  def shell(options={})
    Ripl.shell(options.merge(:history => HISTORY_FILE))
  end

  before do
    reset_ripl
    if defined? Readline
      1.upto(Readline::HISTORY.size) { Readline::HISTORY.shift }
    end
  end
  after { FileUtils.rm_f HISTORY_FILE }

  it "#after_loop saves history" do
    inputs = %w{blih blah}
    inputs.each {|e| shell.history << e }
    shell.after_loop
    File.read(HISTORY_FILE).should == inputs.join("\n")
  end

  it "#before_loop loads previous history" do
    File.open(HISTORY_FILE, 'w') {|f| f.write "check\nthe\nmike" }
    stub(Ripl::Runner).load_rc
    shell.before_loop
    shell.history.to_a.should == %w{check the mike}
  end

  it "#before_loop has empty history if no history file exists" do
    stub(Ripl::Runner).load_rc
    shell.before_loop
    shell.history.to_a.should == []
  end
end
