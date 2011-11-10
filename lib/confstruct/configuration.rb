require "confstruct/hash_with_struct_access"

module Confstruct
  
  class Configuration < HashWithStructAccess
  
    def initialize hash=@@hash_class.new, &block
      super({})
      @default_values = hash.is_a?(HashWithStructAccess) ? hash : HashWithStructAccess.new(hash)
      eval_or_yield @default_values, &block
      reset_defaults!
    end
    
    def after_config! obj
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
    
    def reset_defaults!
      self.replace(default_values.deep_copy)
    end
    
  end
end