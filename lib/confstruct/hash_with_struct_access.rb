require 'delegate'
require 'confstruct/utils'

module Confstruct
  class Deferred < Proc; end
  def self.deferred &block; Deferred.new(&block); end

  if ::RUBY_VERSION < '1.9'
    begin
      require 'active_support/ordered_hash'
      class HashWithStructAccess < DelegateClass(ActiveSupport::OrderedHash); @@ordered = true; @@hash_class = ActiveSupport::OrderedHash; end
    rescue LoadError, NameError
      class HashWithStructAccess < DelegateClass(Hash); @@ordered = false; @@hash_class = Hash; end
    end
  else
    class HashWithStructAccess < DelegateClass(Hash); @@ordered = true; @@hash_class = Hash; end
  end
  
  class HashWithStructAccess
    attr_accessor :default_values
    @default_values = {}
    
    class << self
      def from_hash hash
        symbolized_hash = symbolize_hash hash
        self.new(symbolized_hash)
      end

      def ordered?
        @@ordered
      end
      
      def symbolize_hash hash
        hash.inject(@@hash_class.new) do |h,(k,v)| 
          h[symbolize k] = v.is_a?(Hash) ? symbolize_hash(v) : v
          h
        end
      end
      
      def symbolize key
        (key.to_s.gsub(/\s+/,'_').to_sym rescue key.to_sym) || key
      end
    end
    
    def initialize hash = @@hash_class.new
      super(hash)
    end

    def [] key
      result = super(symbolize(key))
      if result.is_a?(Hash) and not result.is_a?(HashWithStructAccess)
        result = HashWithStructAccess.new(result)
      elsif result.is_a?(Deferred)
        result = eval_or_yield self, &result
      end
      result
    end
    
    def []= key,value
      k = symbolize(key)
      v = (value.is_a?(Hash) and not value.is_a?(HashWithStructAccess)) ? HashWithStructAccess.new(value) : value
      if v.is_a?(Hash) and self[k].is_a?(Hash)
        self[k].replace(v)
      else
        super(k, v)
      end
    end

    def deep_copy
      result = self.class.new(@@hash_class.new)
      self.each_pair do |k,v|
        if v.respond_to?(:deep_copy)
          result[k] = v.deep_copy
        else
          result[k] = Marshal.load(Marshal.dump(v)) rescue v.dup
        end
      end
      result
    end
    alias_method :inheritable_copy, :deep_copy

    def deep_merge hash
      do_deep_merge! hash, self.deep_copy
    end

    def deep_merge! hash
      do_deep_merge! hash, self
    end

    def deferred! &block
      Deferred.new(&block)
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
    
    def inspect
      r = self.keys.collect { |k| "#{k.inspect}=>#{self[k].inspect}" }
      "{#{r.compact.join(', ')}}"
    end
    
    def is_a? klazz
      klazz == @@hash_class or super
    end
    
    def lookup! key_path
      val = self
      keys = key_path.split(/\./)
      keys.each do |key|
        return nil if val.nil?
        if val.respond_to?(:has_key?) and val.has_key?(key.to_sym)
          val = val[key.to_sym]
        else
          return nil
        end
      end
      return val
    end
    
    def method_missing sym, *args, &block
      name = sym.to_s.chomp('=').to_sym
      result = nil
      
      if name.to_s =~ /^add_(.+)!$/
        name = $1.to_sym
        self[name] = [] unless self.has_key?(name)
        unless self[name].is_a?(Array)
          raise TypeError, "Cannot #add! to a #{self[name].class}"
        end
        if args.length > 0
          result = self[name].push *args
        elsif block_given?
          result = HashWithStructAccess.new(@@hash_class.new)
          self[name].push result
        end
      elsif args.length == 1
        result = self[name] = args[0]
      elsif args.length > 1
        super(sym,*args,&block)
      else
        result = self[name]
        if result.nil? and block_given?
          result = self[name] = HashWithStructAccess.new(@@hash_class.new)
        end
      end
      if block_given?
        eval_or_yield result, &block
      end
      result
    end
    
    def methods
      key_methods = keys.collect do |k|
        self[k].is_a?(Deferred) ? k.to_s : [k.to_s, "#{k}="]
      end
      super + key_methods.compact.flatten
    end
    
    def ordered?
      self.class.ordered?
    end
    
    def respond_to? arg
      super(arg) || keys.include?(symbolize(arg.to_s.sub(/=$/,'')))
    end

    def symbolize key
      self.class.symbolize(key)
    end
       
    def values
     keys.collect { |k| self[k] }
    end

    protected 
    def do_deep_merge! source, target
      source.each_pair do |k,v|
        if target.has_key?(k)
          if v.respond_to?(:each_pair) and target[k].respond_to?(:merge)
            do_deep_merge! v, target[k]
          elsif v != target[k]
            target[k] = v
          end
        else
          target[k] = v
        end
      end
      target
    end

  end
end