require "confstruct/hash_with_struct_access"

module Confstruct
  
  def self.ConfigClass defaults=nil, &block
    klazz = Class.new(Confstruct::Configuration)
    klazz.instance_eval do
      @default_values = defaults
      if @default_values.nil?
        @default_values = HashWithStructAccess.new({})
        eval_or_yield @default_values, &block
      end
    end
    klazz
  end
  
  class Configuration < HashWithStructAccess
  
    class << self; attr_accessor :default_values; end
    @default_values = {}
  
    def initialize hash=nil, &block
      super(hash || {})
      initialize_default_values! if hash.nil?
      configure &block if block_given?
    end
    
    def after_config! obj
    end
    
    def initialize_default_values!
      self.class.new(self.class.default_values).deep_copy.each do |k,v|
        self[k] ||= v
      end
    end
  
    def configure *args, &block
      if args[0].respond_to?(:each_pair)
        self.deep_merge!(args[0])
      end
      eval_or_yield self, &block
      after_config! self
      self
    end

    def push! *args, &block
      (self[:@stash] ||= []).push(self.deep_copy)
      configure *args, &block if args.length > 0 or block_given?
      self
    end
    
    def pop!
      s = self[:@stash] 
      if s.nil? or s.empty?
        raise IndexError, "Stash is empty"
      else
        obj = s.pop
        self.clear
        self[:@stash] = s unless s.empty?
        self.merge! obj
        after_config! self
      end
      self
    end
    
  end
end