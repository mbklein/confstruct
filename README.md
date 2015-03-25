# confstruct [![Build Status](https://secure.travis-ci.org/mbklein/confstruct.png)](http://travis-ci.org/mbklein/confstruct) [![Dependency Status](https://gemnasium.com/mbklein/confstruct.png)](https://gemnasium.com/mbklein/confstruct)


<b>Confstruct</b> is yet another configuration gem. Definable and configurable by 
hash, struct, or block, confstruct aims to provide the flexibility to do things your
way, while keeping things simple and intuitive.

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

The configure method will even perform a deep merge for you if you pass it a hash or hash-like object
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

### Other Features

#### Deferred evaluation

Any configuration value of class `Confstruct::Deferred` will be evaluated on access, allowing you to
define read-only, dynamic configuration attributes

    config.app_name = "iWidgetCloud"
    config.msgs.welcome = Confstruct::Deferred.new {|c| "Welcome to #{c.app_name}!"}    
    config.msgs.welcome
     => "Welcome to iWidgetCloud!"
    config.app_name = "Enterprisey-Webscale"
     => "Enterprisey-Webscale" 
    config.welcome_msg
     => "Welcome to Enterprisey-Webscale"
     
As a convenience, `Confstruct.deferred(&block)` and `Confstruct::HashWithStructAccess#deferred!(&block)`
will create a Confstruct::Deferred for you, making the following two assignments equivalent to the above:

    config.welcome_msg = Confstruct.deferred { |c| "Welcome to #{c.app_name}!" }
    config do
      welcome_msg deferred! { |c| RestClient::Resource.new(c.url) }
    end

#### Push/Pop configurations

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
    
#### lookup!

`lookup!` can be used to look up down a hieararchy without raising on missing values; and/or 
to look up with default value. 

    config = Confstruct::Configuration.new do 
      project 'confstruct'
      github do
        url 'http://www.github.com/mbklein/confstruct'
        branch 'master'
      end
    end
    config.lookup!("github.url")
    => "http://www.github.com/mbklein/confstruct"
    config.lookup!("github.no_key")
    => nil # no raising
    config.lookup!("not_there.really.not.there")
    => nil
    config.lookup!("github.not_there", "default_value")
    => "default_value"
    
#### lists

The pattern `add_$key!` can be used to add to or create an array. 

    config = Confstruct::Configuration.new
    config.add_color! "green"
    => ["green"]
    config
    => {:color=>["green"]}
    config.add_color! "red"
    config.color
    => ["green", "red"]
    

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
- <b>v0.2.1</b> - Initialize properly from a nested hash with string (non-symbol) keys
- <b>v0.2.2</b> - Fix ArgumentError on #respond_to?(sym, true)
- <b>v0.2.3</b> - Don't evaluate Deferreds during #inspect
- <b>v0.2.4</b> - Fix deferreds under Ruby 1.9.x
- <b>v0.2.5</b> - #14 #configure loses nested hashes somehow
- <b>v0.2.6</b> - Fix test scoping issue under Ruby 2.1.0+
- <b>v0.2.7</b> - Remove ActiveSupport for Ruby >= 1.9
- <b>v1.0.0</b> - [YANKED] Refactor to use Hashie instead of reinventing all the Hash access stuff
- <b>v1.0.1</b> - Switch back to symbolized keys internally

## Contributing to confstruct

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## License

confstruct is released under the [MIT License](http://www.opensource.org/licenses/MIT).
