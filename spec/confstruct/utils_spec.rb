require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Kernel.eval_or_yield" do
  before :each do
    @obj = double('obj')
  end
  
  it "should instance_eval when the block takes no params" do
    expect(@obj).to receive(:test_method).and_return('OK')
    eval_or_yield(@obj) {
      self.should_not == @obj
      self.test_method.should == 'OK'
    }
  end
  
  it "should yield when the block takes a param" do
    expect(@obj).to receive(:test_method).and_return('OK')
    eval_or_yield(@obj) { |o|
      self.should_not == @obj
      o.should == @obj
      lambda { self.test_method }.should raise_error(NoMethodError)
      o.test_method.should == 'OK'
    }
  end
  
  it "should return the object when no block is given" do
    eval_or_yield(@obj).should == @obj
  end
  
end

