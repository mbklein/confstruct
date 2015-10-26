require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Confstruct::Configuration do

  it "should initialize empty" do
    conf = Confstruct::Configuration.new
    conf.is_a?(Hash).should be_truthy
    conf.is_a?(Confstruct::Configuration).should be_truthy
    conf.should == {}
  end
  
  it "should initialize properly from a nested hash with string keys" do
    x = { 'a' => { 'b' => 'c' } }
    conf = Confstruct::Configuration.new(x)
    conf.is_a?(Hash).should be_truthy
    conf.is_a?(Confstruct::Configuration).should be_truthy
    conf[:a][:b].should == 'c'
    conf['a']['b'].should == 'c'
    conf.a.b.should == 'c'
  end

  context "default values" do
    before :all do
      @defaults = { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :branch => 'master'
        }
      }
    end
    
    before :each do
      @config = Confstruct::Configuration.new(@defaults)
    end
    
    it "should have the correct defaults" do
      @config.default_values.should == @defaults
      @config.should == @defaults
    end
    
    it "can be defined in block mode" do
      config = Confstruct::Configuration.new do
        project 'confstruct'
        github do
          url 'http://www.github.com/mbklein/confstruct'
          branch 'master'
        end
      end

      config.default_values.should == @defaults
      config.should == @defaults
    end
  end
  
  context "configuration" do
    before :all do
      @defaults = { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :branch => 'master'
        }
      }
      
      @configured = { 
        :project => 'other-project', 
        :github => { 
          :url => 'http://www.github.com/mbklein/other-project',
          :branch => 'master'
        }
      }
    end

    before :each do
      @config = Confstruct::Configuration.new(@defaults)
    end
    
    it "should deep merge a hash" do
      @config.configure({ 'project' => 'other-project', 'github' => { 'url' => 'http://www.github.com/mbklein/other-project' } })

      @config.should == @configured
    end

    it "should configure as a struct" do
      @config.project = 'other-project'
      @config.github.url = 'http://www.github.com/mbklein/other-project'
      @config.should == @configured
    end
    
    it "should configure as a block" do
      @config.configure do
        project 'other-project'
        github do
          url 'http://www.github.com/mbklein/other-project'
        end
      end
      @config.should == @configured
    end

    # Failed in Ruby 2.1 pre-Hashie base
    it "should configure as a block with lambda" do
      conf = Confstruct::Configuration.new
      conf.configure do      
        my_key lambda {|a| a}  
      end 
      conf.my_key.should be_kind_of(Proc)
    end

    it "should raise on reserved words in block mode" do    
      conf = Confstruct::Configuration.new
      expect do
        conf.configure do      
          inspect "inspect is reserved'"
        end 
      end.to raise_error(ArgumentError)
    end

    
    it "should save and restore state via #push! and #pop!" do   
      @config.push!({ :project => 'other-project', :github => { :url => 'http://www.github.com/mbklein/other-project' } })
      @configured.each_pair { |k,v| @config[k].should == v }
      @config.pop!
      @defaults.each_pair { |k,v| @config[k].should == v }
    end
    
    it "should raise an exception when popping an empty stash" do
      lambda { @config.pop! }.should raise_error(IndexError)
    end

    it "should #reset_defaults!" do
      @config.project = 'other-project'
      @config.github.url = 'http://www.github.com/mbklein/other-project'
      @config.should == @configured
      @config.reset_defaults!
      @config.should == @defaults
    end
    
    it "should call #after_config! when configuration is complete" do
      postconfigurator = double('after_config!')
      postconfigurator.should_receive(:configured!).once.with(@config)
      def @config.after_config! obj
        obj.project.should == 'other-project'
        obj.mock.configured!(obj)
      end
      @config.configure do
        project 'other-project'
        mock postconfigurator
      end
    end

    it "should be initializable with a string-keyed hash" do
      conf = Confstruct::Configuration.new
      conf.configure(:top=>{:middle=>{"one"=>"two"}})
      conf.top.middle.one.should == 'two'
    end
  end

end
