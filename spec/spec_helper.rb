$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rspec'
require 'rspec/autorun'

require 'rubygems'
require 'active_support/core_ext/object/blank'
require 'confstruct'

RSpec.configure do |config|
  
end
