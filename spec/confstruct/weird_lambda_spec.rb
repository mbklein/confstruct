require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "lambda is weird" do

  it "should allow lambdas" do
    conf = Confstruct::Configuration.new

    conf.configure do      
      my_key lambda {|a| a}  
    end 
        
    puts conf.inspect

    expect(conf.my_key).to be_kind_of(Proc)    
  end

end