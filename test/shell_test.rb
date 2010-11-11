require File.join(File.dirname(__FILE__), 'test_helper')

describe "Shell" do
  before { reset_ripl }

  def shell(options={})
    Ripl.shell(options)
  end

  describe "#during_loop" do
    it "exits with exit" do
      mock(shell).get_input { 'exit' }
      dont_allow(shell).loop_once
      shell.during_loop
    end

    it "exits with Control-D" do
      mock(shell).get_input { nil }
      dont_allow(shell).loop_once
      shell.during_loop
    end
  end

  describe "#prompt" do
    it "as a string" do
      shell(:prompt=>'> ').prompt.should == '> '
    end

    it "as a lambda" do
      shell(:prompt=>lambda { "#{10 + 10}> " }).prompt.should == '20> '
    end
  end

  describe "#loop_once" do
    before { @line = shell.line; shell.loop_once("10 ** 2") }

    describe "normally" do
      it "sets last_result" do
        shell.last_result.should == 100
      end

      it "sets _" do
        shell.loop_once('_')
        shell.last_result.should == 100
      end

      it "increments line" do
        shell.line.should == @line + 1
      end
    end

    describe "with error" do
      before {
        @line = shell.line
        @stderr = capture_stderr { shell.loop_once('{') }
      }

      it "prints it" do
        @stderr.should =~ /^SyntaxError: compile error/
      end

      it "sets @error_raised" do
        shell.instance_variable_get("@error_raised").should == true
      end

      it "increments line" do
        shell.line.should == @line + 1
      end
    end
  end
end
