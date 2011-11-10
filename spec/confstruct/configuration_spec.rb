require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'confstruct/configuration'

describe Confstruct::Configuration do

  it "should initialize empty" do
    conf = Confstruct::Configuration.new
    conf.is_a?(Hash).should be_true
    conf.is_a?(Confstruct::Configuration).should be_true
    conf.should == {}
  end

  context "subclass" do
    before :all do
      @defaults = { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :branch => 'master'
        }
      }
      @test_config_class = Confstruct::ConfigClass(@defaults)
    end
    
    before :each do
      @config = @test_config_class.new
    end
    
    it "should have the correct defaults" do
      @test_config_class.default_values.should == @defaults
    end
    
    it "should instantiate with the correct default values" do
      @config.should == @defaults
      @config.object_id.should_not == @defaults.object_id
    end
    
    it "can be defined in block mode" do
      block_config_class = Confstruct.ConfigClass do
        project 'confstruct'
        github do
          url 'http://www.github.com/mbklein/confstruct'
          branch 'master'
        end
      end
      block_config_class.default_values.should == @defaults
      block_config_class.new.should == @defaults
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
      
      TestConfigClass = Confstruct::ConfigClass(@defaults)
    end

    before :each do
      @config = TestConfigClass.new
    end
    
    it "should deep merge a hash" do
      @config.configure({ :project => 'other-project', :github => { :url => 'http://www.github.com/mbklein/other-project' } })
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
    
    it "should save and restore state via #push! and #pop!" do
      @config.push!({ :project => 'other-project', :github => { :url => 'http://www.github.com/mbklein/other-project' } })
      @configured.each_pair { |k,v| @config[k].should == v }
      @config.pop!
      @defaults.each_pair { |k,v| @config[k].should == v }
    end
    
    it "should raise an exception when popping an empty stash" do
      lambda { @config.pop! }.should raise_error(IndexError)
    end

    it "should call #after_config! when configuration is complete" do
      postconfigurator = RSpec::Mocks::Mock.new('after_config!')
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
  end

end
