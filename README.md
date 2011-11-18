# confstruct

<b>Confstruct</b> is yet another configuration gem. Definable and configurable by 
hash, struct, or block, confstruct aims to provide the flexibility to do things your
way, while keeping things simple and intuitive.

[![Build Status](https://secure.travis-ci.org/mbklein/confstruct.png)](http://travis-ci.org/mbklein/confstruct)

## Usage

First, either create an empty `ConfStruct::Configuration` object:

    config = Confstruct::Configuration.new
    
Or with some default values:

    config = Confstruct::Configuration.new({ 
      :project => 'confstruct', 
      :github => { 
        :url => 'http://www.github.com/mbklein/confstruct',
        :branch => 'master'
      }
    })

The above can also be done in block form:

    config = Confstruct::Configuration.new do 
      project 'confstruct'
      github do
        url 'http://www.github.com/mbklein/confstruct'
        branch 'master'
      end
    end
    
There are many ways to access and configure the resulting `config` object...

As a struct...

    config.project = 'other-project'
    config.github.url = 'http://www.github.com/somefork/other-project'
    config.github.branch = 'pre-1.0'
  
As a block...

    config.configure do
      project 'other-project'
      github.url 'http://www.github.com/somefork/other-project'
      github.branch 'pre-1.0'
    end

As a hash...

    config[:github][:url] = 'http://www.github.com/somefork/other-project'
    
Or even as a crazy struct/hash hybrid...

    config.github[:url] = 'http://www.github.com/somefork/other-project'
    config[:github].branch = 'pre-1.0'
    
Each sub-hash/struct is a configuration object in its own right, and can be
treated as such. (Note the ability to leave the `configure` method
off the inner call.)

    config.configure do
      project 'other-project'
      github do
        url 'http://www.github.com/somefork/other-project'
        branch 'pre-1.0'
      end
    end

You can even

    config.project = 'other-project'
    config.github = { :url => 'http://www.github.com/somefork/other-project', :branch => 'pre-1.0' }

The configure method will even a deep merge for you if you pass it a hash or hash-like object
(anything that responds to `each_pair`)

    config.configure({:project => 'other-project', :github => {:url => 'http://www.github.com/somefork/other-project', :branch => 'pre-1.0'}})

Because it's "hashes all the way down," you can store your defaults and/or configurations
in YAML files, or in Ruby scripts if you need to evaluate expressions at config-time.

However you do it, the resulting configuration object can be accessed either as a
hash or a struct:

    config.project
     => "other-project" 
    config[:project]
     => "other-project" 
    config.github
     => {:url=>"http://www.github.com/somefork/other-project", :branch=>"pre-1.0"}
    config.github.url
     => "http://www.github.com/somefork/other-project" 
    config.github[:url]
     => "http://www.github.com/somefork/other-project" 
    config[:github]
     => {:url=>"http://www.github.com/somefork/other-project", :branch=>"pre-1.0"}

### Advanced Tips & Tricks

Any configuration value of class `Confstruct::Deferred` will be evaluated on access, allowing you to
define read-only, dynamic configuration attributes

    config[:github][:client] = Confstruct::Deferred.new { |c| RestClient::Resource.new(c.url) }
     => #<Proc:0x00000001035eb240>
    config.github.client 
     => #<RestClient::Resource:0x1035e3b30 @options={}, @url="http://www.github.com/mbklein/confstruct", @block=nil> 
    config.github.url = 'http://www.github.com/somefork/other-project'
     => "http://www.github.com/somefork/other-project" 
    config.github.client 
     => #<RestClient::Resource:0x1035d5bc0 @options={}, @url="http://www.github.com/somefork/other-project", @block=nil>
     
As a convenience, `Confstruct.deferred(&block)` and `Confstruct::HashWithStructAccess#deferred!(&block)`
act like `lambda`, making the following two assignments equivalent to the above:

    config.github.client = Confstruct.deferred { |c| RestClient::Resource.new(c.url) }
    config.github do
      client deferred! { |c| RestClient::Resource.new(c.url) }
    end

`push!` and `pop!` methods allow you to temporarily override some or all of your configuration values. This can be
useful in spec tests where you need to change values but don't want to worry about messing up tests that depend
on the same global configuration object.

    config.github.url
     => "http://www.github.com/mbklein/confstruct"
    config.push! { github.url 'http://www.github.com/somefork/other-project' }
     => {:project=>"confstruct", :github=>{:branch=>"master", :url=>"http://www.github.com/somefork/other-project"}} 
    config.github.url
     => "http://www.github.com/somefork/other-project"
    config.pop!
     => {:project=>"confstruct", :github=>{:branch=>"master", :url=>"http://www.github.com/mbklein/confstruct"}} 
    config.github.url
     => "http://www.github.com/mbklein/confstruct"

### Notes

* Confstruct will attempt to use ordered hashes internally when available.
  * In Ruby 1.9 and above, this is automatic.
  * In Rubies earlier than 1.9, Confstruct will try to require and use ActiveSupport::OrderedHash, 
    falling back to a regular Hash if necessary. The class/instance method `ordered?` can be used 
    to determine if the hash is ordered or not.
* In order to support struct access, all hash keys are converted to symbols, and are accessible
  both as strings and symbols (like a `HashWithIndifferentAccess`). In other words, config['foo'] 
  and config[:foo] refer to the same value.
  
## Release History

- <b>v0.1.0</b> - Initial release
- <b>v0.2.0</b> - Add fallback value to HashWithStructAccess#lookup!, native support for Rails I18n.

## Contributing to confstruct

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Michael B. Klein. See LICENSE.txt for further details.

