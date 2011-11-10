require 'delegate'
require 'confstruct/utils'

module Confstruct
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

    def inspect
      r = self.keys.collect { |k| self[k].is_a?(Proc) or k.to_s =~ /^@/ ? nil : "#{k.inspect}=>#{self[k].inspect}" }
      "{#{r.compact.join(', ')}}"
    end
    
    def is_a? klazz
      klazz == Hash or super
    end
    
    alias_method :_keys, :keys
    def keys
      _keys.reject { |k| self[k].is_a?(Proc) or k.to_s =~ /^@/ }
    end
    
    def values
      keys.collect { |k| self[k] }
    end
    
    def method_missing sym, *args, &block
      if args.length > 1
        super(sym,*args,&block)
      end
      
      name = sym.to_s.chomp('=').to_sym
      if args.length == 1
        self[name] = args[0]
      else
        result = self[name]
        if result.nil? and block_given?
          result = self[name] = HashWithStructAccess.new(@@hash_class.new)
        end

        if result.is_a?(HashWithStructAccess) and block_given?
          eval_or_yield result, &block
        elsif result.is_a?(Proc) 
          result = eval_or_yield self, &result
        end
        result
      end
    end
    
    def methods
      key_methods = _keys.collect do |k|
        if k.to_s =~ /^@/ 
          nil
        else
          self[k].is_a?(Proc) ? k.to_s : [k.to_s, "#{k}="]
        end
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