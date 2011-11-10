require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'confstruct/utils'

describe "Kernel.eval_or_yield" do
  before :all do
    @obj = RSpec::Mocks::Mock.new('obj')
  end
  
  it "should instance_eval when the block takes no params" do
    @obj.should_receive(:test).and_return('OK')
    eval_or_yield(@obj) { 
      self.should_not == @obj
      self.test.should == 'OK'
    }
  end
  
  it "should yield when the block takes a param" do
    @obj.should_receive(:test).and_return('OK')
    eval_or_yield(@obj) { |o|
      self.should_not == @obj
      o.should == @obj
      lambda { self.test }.should raise_error(NoMethodError)
      o.test.should == 'OK'
    }
  end
  
  it "should return the object when no block is given" do
    eval_or_yield(@obj).should == @obj
  end
  
end

