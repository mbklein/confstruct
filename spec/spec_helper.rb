$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rspec'
require 'rspec/autorun'

require 'rubygems'
require 'confstruct'

require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  
end




# Two hashes are equal even if one has symbols as keys
# and another strings. works on nested hashes too. 
require 'hashie'
class IndifferentHashieHash < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
end

RSpec::Matchers.define :match_indifferently do |expected|
  match do |actual|
    IndifferentHashieHash.new(actual.to_hash) ==  IndifferentHashieHash.new(expected.to_hash)
  end
end
