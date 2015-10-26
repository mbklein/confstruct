require 'hashie'
require 'confstruct/utils'


module Confstruct
  class Deferred
    attr_reader :block
    def initialize &block
      @block = block
    end
    def inspect(full=false)
      if full
        super
      else
        "(deferred)"
      end
    end
  end
  def self.deferred &block; Deferred.new(&block); end
  
  def self.i18n key=nil, &block
    raise NameError, "I18n handler not loaded" unless Object.const_defined? :I18n # ensure the Rails I18n handler is loaded
    Deferred.new do |hwsa|
      val = block_given? ? eval_or_yield(hwsa, &block) : key
      if val.is_a?(Date) or val.is_a?(Time) or val.is_a?(DateTime)
        ::I18n.localize val
      else
        ::I18n.translate val
      end
    end
  end

  
  class HashWithStructAccess < Hashie::Mash
    include Hashie::Extensions::Mash::SafeAssignment
    include Hashie::Extensions::DeepMerge


    attr_accessor :default_values
    @default_values = {}
    
    # Hashie::Mash normally standardizes all keys as strings
    # We can override this method to standardize as symbols either,
    # for backwards-compat with previous Confstruct. 
    # Turns out changing this effects things like merges into ordinary hashes
    # that client code might be doing, and makes a backward compat
    # nightmare. 
    def convert_key(key)
      key.to_sym
    end

    def self.from_hash(hash)
      self.new(hash)
    end

    # We need an #inspect that does not evlauate Deferreds. 
    # We use #fetch instead of #[], since fetch does not evaluate
    # Deferreds. Otherwise copied from hashie's pretty_inspect
    def inspect
      ret = "#<#{self.class}"
      keys.sort_by(&:to_s).each do |key|
        ret << " #{key}=#{self.fetch(key).inspect}"
      end
      ret << '>'
      ret
    end
    

    def deep_copy
      # Hashie::Mash dup does a deep copy already, hooray. 
      self.dup
    end
    alias_method :inheritable_copy, :deep_copy

    # Override for Deferred support
    def [] key
      result = super
      if result.is_a?(Deferred)
        result = eval_or_yield self, &result.block
      end
      result
    end

    # values override needed to ensure Deferreds get evaluated
    def values
      keys.collect { |k| self[k] }
    end

    def deferred! &block
      Confstruct.deferred(&block)
    end
    
    def has? key_path
      val = self
      keys = key_path.split(/\./)
      keys.each do |key|
        return false if val.nil?
        if val.respond_to?(:has_key?) and val.has_key?(key.to_sym)
          val = val[key.to_sym]
        else
          return false
        end
      end
      return true
    end
    
    def i18n! key=nil, &block
      Confstruct.i18n(key,&block)
    end
    
    
    def lookup! key_path, fallback = nil
      val = self
      keys = key_path.split(/\./)
      keys.each do |key|
        return fallback if val.nil?
        if val.respond_to?(:has_key?) and val.has_key?(key.to_sym)
          val = val[key.to_sym]
        else
          return fallback
        end
      end
      return val
    end

    def self.structurize hash
      result = hash
      if result.is_a?(Hash) and not result.is_a?(HashWithStructAccess)
        result = HashWithStructAccess.new(result)
      end
      result
    end
    
    def method_missing sym, *args, &block
      name = sym.to_s.chomp('=').to_sym
      result = nil
      
      if name.to_s =~ /^add_(.+)!$/
        name = $1.to_sym
        self.assign_property(name, []) unless self.has_key?(name)
        unless self[name].is_a?(Array)
          raise TypeError, "Cannot #add! to a #{self[name].class}"
        end
        if args.length > 0
          local_args = args.collect { |a| self.class.structurize a }
          result = self[name].push *local_args
        elsif block_given?
          result = HashWithStructAccess.new
          self[name].push result
        end
      elsif args.length == 1
        self.assign_property(name, args[0])
        result = self[name]
      elsif args.length > 1
        super(sym,*args,&block)
      else
        result = self[name]
        if result.nil? and block_given?
          self.assign_property(name, HashWithStructAccess.new)
          result = self[name]
        end
      end
      if block_given?
        eval_or_yield result, &block
      end
      result
    end
    
  end
end
