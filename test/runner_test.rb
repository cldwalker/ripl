require File.join(File.dirname(__FILE__), 'test_helper')

describe "Runner" do
  describe ".run" do
    describe "with -I option" do
      before { @old_load_path = $:.dup }
      after { $:.replace @old_load_path }

      it "and equal sign adds to $LOAD_PATH" do
        ripl("-I=blah", :start=>true)
        $:[0].should == 'blah'
      end

      it "and no equal sign adds to $LOAD_PATH" do
        ripl("-Ispec", :start=>true)
        $:[0].should == 'spec'
      end

      it "and whitespace delimited argument adds to $LOAD_PATH" do
        ripl("-I", "spec", :start=>true)
        $:[0].should == 'spec'
      end

      it "containing multiple paths adds to $LOAD_PATH" do
        ripl("-I=app:lib", :start=>true)
        $:[0,2].should == ['app', 'lib']
      end

      it "called more than once adds to $LOAD_PATH" do
        ripl("-Ilib", "-Ispec", :start=>true)
        $:[0,2].should == ['spec', 'lib']
      end

      it "with invalid argument doesn't add to $LOAD_PATH" do
        previous_size = $:.size
        ripl("-I", :start=>true)
        $:.size.should == previous_size
      end
    end

    describe "with -r option" do
      it "and equal sign requires path" do
        mock(Runner).require('rip')
        ripl("-r=rip", :start=>true)
      end

      it "and no equal sign requires path" do
        mock(Runner).require('rip')
        ripl("-rrip", :start=>true)
      end

      it "and whitespace delimited argument requires path" do
        mock(Runner).require('rip')
        ripl("-r", "rip", :start=>true)
      end

      it "called more than once requires paths" do
        mock(Runner).require('rip')
        mock(Runner).require('dude')
        ripl("-rrip", "-rdude", :start=>true)
      end

      it "with invalid argument requires blank" do
        mock(Runner).require('')
        ripl('-r', :start=>true)
      end
    end

    it "with -f option doesn't load irbrc" do
      mock(Shell).create(anything) {|e|
        shell = Shell.new(e)
        mock(shell).during_loop
        dont_allow(Runner).load_rc(anything)
        shell
      }
      ripl("-f")
    end

    it "with -d option sets $DEBUG" do
      ripl("-d", :start=>true)
      $DEBUG.should == true
      $DEBUG = nil
    end

    it "with -v option prints version" do
      should.raise(SystemExit) { ripl("-v").should == Ripl::VERSION }
    end

    it "with -h option prints help" do
      should.raise(SystemExit) {
        actual = ripl("-v")
        actual.should =~ /^Usage: ripl/
        actual.should =~ /Options:\n  -f/
      }
    end

    it "with invalid options prints errors" do
      capture_stderr {
        ripl('--blah', '-z', :start=>true)
      }.chomp.should == "ripl: invalid option `blah'\nripl: invalid option `z'"
    end
  end
end
