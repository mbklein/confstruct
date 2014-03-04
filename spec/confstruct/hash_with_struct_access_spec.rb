require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Confstruct::HashWithStructAccess do
  
  it "should initialize empty" do
    hwsa = Confstruct::HashWithStructAccess.new
    hwsa.is_a?(Hash).should be_true
    hwsa.is_a?(Confstruct::HashWithStructAccess).should be_true
    hwsa.should == {}
  end
  
  it "should respond to #ordered?" do
    hwsa = Confstruct::HashWithStructAccess.new
    [true,false].should include(hwsa.ordered?)
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
    
    it "should properly respond to #has?" do
      @hwsa.has?('github.url').should be_true
      @hwsa.has?('github.foo.bar.baz').should be_false
    end
    
    it "should properly respond to #lookup!" do
      @hwsa.lookup!('github.url').should == @hash[:github][:url]
      @hwsa.lookup!('github.foo.bar.baz',:default).should == :default
      @hwsa.lookup!('github.foo.bar.baz').should be_nil
      @hwsa.github.quux = nil
      @hwsa.lookup!('github.quux',:default).should be_nil
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
    
    it "should eval_or_yield all types" do
      @hwsa.github do
        items([]) do
          self.should == []
          push 1
          push 'two'
          push :III
          self.should == [1,'two',:III]
        end
      end
      @hwsa.github.items.should == [1,'two',:III]
    end
    
    it "should fail on other method signatures" do
      lambda { @hwsa.error(1, 2, 3) }.should raise_error(NoMethodError)
    end
    
    it "should create arrays on the fly" do
      @hwsa.github do
        add_roles!({:jeeves => :valet}, {:wooster => :dolt})
        add_roles! do
          psmith :chum
        end
      end
      @hwsa.github.roles.should == [{:jeeves => :valet}, {:wooster => :dolt}, {:psmith => :chum}]
      @hwsa.github.roles.first.jeeves.should == :valet
    end
    
    it "should not allow #add!ing to non-Array types" do
      lambda { 
        @hwsa.github do
          add_url! 'https://github.com/mbklein/busted'
        end
      }.should raise_error(TypeError)
    end
    
  end

  context "Proc values as virtual methods" do
    before :all do
      @hash = { 
        :project => 'confstruct', 
        :github => { 
          :url => 'http://www.github.com/mbklein/confstruct',
          :default_branch => 'master',
          :regular_proc => lambda { |a,b,c| puts "#{a}: #{b} #{c}" },
          :reverse_url => Confstruct.deferred { self.url.reverse },
          :upcase_url => Confstruct.deferred { |c| c.url.upcase },
          :introspective => Confstruct.deferred { |c| c }
        }
      }
    end
  
    before :each do
      @hwsa = Confstruct::HashWithStructAccess.from_hash(@hash)
    end
    
    it "should only evaluate Confstruct::Deferred procs" do
      @hwsa.github.regular_proc.is_a?(Proc).should be_true
      @hwsa.github.upcase_url.is_a?(Proc).should be_false
      @hwsa.github.reverse_url.is_a?(Proc).should be_false
    end
    
    it "should instance_eval the proc with no params" do
      @hwsa.github.reverse_url.should == @hash[:github][:url].reverse
    end

    it "should call the proc with params" do
      @hwsa.github.upcase_url.should == @hash[:github][:url].upcase
    end
        
    it "should evaluate deferreds when enumerating values" do
      @hash[:github].values.should_not include(@hash[:github][:url].reverse)
      @hwsa.github.values.should include(@hash[:github][:url].reverse)
    end

    it "should not evaluate deferreds when inspecting" do
      s = @hwsa.inspect
      s.should =~ %r{:reverse_url=>\(deferred\)}
      s.should =~ %r[:regular_proc=>#<Proc:]
    end
    
    it "should allow definition of deferreds in block mode" do
      @hwsa.github do
        defproc deferred! { reverse_url + upcase_url }
        regproc Kernel.lambda { reverse_url + upcase_url }
      end
      @hwsa.github.defproc.is_a?(Proc).should be_false
      @hwsa.github.defproc.should == @hwsa.github.reverse_url + @hwsa.github.upcase_url
      @hwsa.github.regproc.is_a?(Proc).should be_true
    end
    
    it "should handle i18n translations" do
      t = Time.now
      I18n = RSpec::Mocks::Mock.new('I18n')
      I18n.should_receive(:translate).with('Hello, World!').and_return('Bonjour, Monde!')
      I18n.should_receive(:localize).with(t).and_return('French Time!')
      @hwsa.github do
        hello 'Hello, World!'
        time t
        local_hello i18n! { hello }
        local_time i18n! { time }
      end
      @hwsa.github.local_hello.should == 'Bonjour, Monde!'
      @hwsa.github.local_time.should == 'French Time!'
    end

    it "should send the confstruct object as a parameter when evaluating the deferred" do
      @hwsa.github.introspective.should be_a_kind_of(Confstruct::HashWithStructAccess)
    end
      
  end
  
  context "delegation" do
    before :each do
      @hwsa = Confstruct::HashWithStructAccess.from_hash('a' => { 'b' => { 'c' => 'd' } })
    end
    
    it "should always return HashWithStructAccess hashes" do
      @hwsa.a.b.should be_a Confstruct::HashWithStructAccess
    end

    it "should gracefully handle being extended" do
      pending %{probably won't fix due to the unpredictable way ActiveSupport injects #presence()}
      @hwsa.a.b.presence.should be_a Confstruct::HashWithStructAccess
    end
  end
  
  context "bug fixes" do
    hwsa = Confstruct::HashWithStructAccess.from_hash('a' => { 'b' => { 'c' => 'd' } })
    it "should handle the two-argument form of #respond_to?" do
      lambda { hwsa.respond_to? :something, true }.should_not raise_error
    end
  end
  
end
