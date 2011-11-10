require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'confstruct/hash_with_struct_access'

describe Confstruct::HashWithStructAccess do
  
  it "should initialize empty" do
    hwsa = Confstruct::HashWithStructAccess.new
    hwsa.is_a?(Hash).should be_true
    hwsa.is_a?(Confstruct::HashWithStructAccess).should be_true
    hwsa.should == {}
  end
  
  context "data manipulation" do
    before :all do
      @hash = { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :default_branch => 'master'
        }
      }
    end
  
    before :each do
      @hwsa = Confstruct::HashWithStructAccess.from_hash(@hash)
    end
    
    it "should initialize from a hash" do
      hwsa = Confstruct::HashWithStructAccess.from_hash({ 
        'project' => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          'default branch' => 'master'
        }
      })

      hwsa.should == @hwsa
      hwsa.should == @hash
    end
    
    it "should provide hash access" do
      @hwsa[:project].should == @hash[:project]
      @hwsa['project'].should == @hash[:project]
      @hwsa[:github].should == @hash[:github]
      @hwsa[:github][:url].should == @hash[:github][:url]
    end
    
    it "should provide struct access" do
      @hwsa.project.should == @hash[:project]
      @hwsa.github.should == @hash[:github]
      @hwsa.github.url.should == @hash[:github][:url]
    end
    
    it "should provide block access" do
      u = @hash[:github][:url]
      @hwsa.github do
        url.should == u
      end
      
      @hwsa.github do |g|
        g.url.should == @hash[:github][:url]
      end
    end
    
    it "should provide introspection" do
      @hwsa.should_respond_to(:project)
      @hash.keys.each do |m| 
        @hwsa.methods.should include("#{m}")
        @hwsa.methods.should include("#{m}=")
      end
    end
    
    it "should #deep_merge" do
      hwsa = @hwsa.deep_merge({ :new_foo => 'bar', :github => { :default_branch => 'develop' } })
      @hwsa.should == @hash
      hwsa.should_not == @hwsa
      hwsa.should_not == @hash
      hwsa.should == { 
        :new_foo => 'bar',
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :default_branch => 'develop'
        }
      }
    end

    it "should #deep_merge!" do
      @hwsa.deep_merge!({ :github => { :default_branch => 'develop' } })
      @hwsa.should_not == @hash
      @hwsa.should == { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :default_branch => 'develop'
        }
      }
    end
    
    it "should create values on demand" do
      @hwsa.github.foo = 'bar'
      @hwsa.github.should == { 
        :foo => 'bar',
        :url => 'http://www.github.com/mbklein/confstruct',
        :default_branch => 'master'
      }

      @hwsa.baz do
        quux 'default_for_quux'
      end
      @hwsa[:baz].should == { :quux => 'default_for_quux' }
    end

    it "should replace an existing hash" do
      @hwsa.github = { :url => 'http://www.github.com/somefork/other-project', :branch => 'pre-1.0' }
      @hwsa.github.has_key?(:default_branch).should == false
      @hwsa.github.should == { :url => 'http://www.github.com/somefork/other-project', :branch => 'pre-1.0' }
    end
    
    it "should fail on other method signatures" do
      lambda { @hwsa.error(1, 2, 3) }.should raise_error(NoMethodError)
    end
  end

  context "Proc values as virtual methods" do
    before :all do
      @hash = { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :default_branch => 'master',
          :reverse_url => lambda { self.url.reverse },
          :upcase_url => lambda { |c| c.url.upcase }
        }
      }
    end
  
    before :each do
      @hwsa = Confstruct::HashWithStructAccess.from_hash(@hash)
    end
    
    it "should instance_eval the proc with no params" do
      @hwsa.github.reverse_url.should == @hash[:github][:url].reverse
    end

    it "should call the proc with params" do
      @hwsa.github.upcase_url.should == @hash[:github][:url].upcase
    end
    
    it "should ignore procs when enumerating keys" do
      @hash[:github].keys.length.should == 4
      @hwsa.github.keys.length.should == 2
    end
    
    it "should ignore procs when enumerating values" do
      @hash[:github].values.length.should == 4
      @hwsa.github.values.length.should == 2
    end

    it "should ignore procs when inspecting" do
      s = @hwsa.inspect
      s.should =~ /:github=>/
      s.should =~ /:url=>/
      s.should_not =~ /:reverse_url=>/
    end
  end
end