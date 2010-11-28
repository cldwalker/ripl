require File.join(File.dirname(__FILE__), 'test_helper')

describe "Shell" do
  before { reset_ripl }

  def shell(options={})
    Ripl.shell(options)
  end

  describe "#loop" do
    before { mock(shell).before_loop }
    it "exits with exit" do
      mock(shell).get_input { 'exit' }
      dont_allow(shell).eval_input
      shell.loop
    end

    it "exits with quit" do
      mock(shell).get_input { 'quit' }
      dont_allow(shell).eval_input
      shell.loop
    end

    it "exits with Control-D" do
      mock(shell).get_input { nil }
      dont_allow(shell).eval_input
      shell.loop
    end
  end

  describe "#prompt" do
    it "from a string" do
      shell(:prompt=>'> ').prompt.should == '> '
    end

    it "from a lambda" do
      shell(:prompt=>lambda { "#{10 + 10}> " }).prompt.should == '20> '
    end

    it "rescues from a failed lambda" do
      capture_stderr {
        shell(:prompt=>lambda { wtf }).prompt.should == Shell::OPTIONS[:prompt]
      }.should =~ /ripl: Error while creating.*NameError.*`wtf'/m
    end
  end

  describe "#before_loop" do
    before_all { Ripl::Commands.send(:define_method, :ping) { 'pong' } }
    it "adds commands to main from Commands" do
      stub(Ripl::Runner).load_rc
      stub(Kernel).at_exit
      Ripl.shell.before_loop
      Ripl.shell.loop_eval("ping").should == 'pong'
    end

    it "adds commands to fixnum from Commands" do
      stub(Ripl::Runner).load_rc
      Ripl.shell.binding = 1.send(:binding)
      stub(Kernel).at_exit
      Ripl.shell.before_loop
      Ripl.shell.loop_eval("ping").should == 'pong'
    end
  end

  describe "#eval_input" do
    before { @line = shell.line; shell.eval_input("10 ** 2") }

    describe "normally" do
      it "sets result" do
        shell.result.should == 100
      end

      it "sets _" do
        shell.eval_input('_')
        shell.result.should == 100
      end

      it "increments line" do
        shell.line.should == @line + 1
      end
    end

    describe "with error" do
      before {
        @line = shell.line
        @stderr = capture_stderr { shell.eval_input('{') }
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

  describe "API#" do
    Shell::API.instance_methods.delete_if {|e| e[/=$/]}.each do |meth|
      it "#{meth} is accessible to plugins" do
        mod = Object.const_set "Ping_#{meth}", Module.new
        mod.send(:define_method, meth) { "pong_#{meth}" }
        Shell.send :include, mod
        shell.send(meth).should == "pong_#{meth}"
      end
    end
  end
end
