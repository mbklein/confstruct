# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "confstruct"

Gem::Specification.new do |s|
  s.name        = "confstruct"
  s.version     = Confstruct::VERSION
  s.authors     = ["Michael Klein"]
  s.email       = ["mbklein@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A simple, hash/struct-based configuration object}
  s.description = %q{A simple, hash/struct-based configuration object}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  if ::RUBY_VERSION < '1.9'
    s.add_development_dependency 'active_support'
  end

  s.add_dependency "hashie", "~> 3.3"
  
  s.add_development_dependency "rake", ">=0.8.7"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "rspec", "~> 2.99"
  s.add_development_dependency "yard"
  
end
