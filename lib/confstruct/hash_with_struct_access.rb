require 'delegate'

##############
# Confstruct::HashWithStructAccess is a Hash wrapper that provides deep struct access
# 
# Initialize from a hash:
# h = Confstruct::HashWithStructAccess.from_hash({ :one => 1, :two => {:three => 3, :four => 4} })
# 
# Access it like a hash or a struct, all the way down:
# h[:one]
# => 1
# Or a struct:
# h.one
# => 1
# h.two.respond_to?(:three)
# => true
# h.two.three
# => 3
# h[:two][:three]
# => 3
# h.two.five = 5
# => 5
# 
# Yield sub-structs:
# h.two { |t| t.three = 'three' }
# 
# h
# => {:one=>1, :two=>{:three=>"three", :four=>4, :five=>5}}
#############

module Confstruct
  class HashWithStructAccess < DelegateClass(Hash)
    
    class << self
      def from_hash hash
        symbolized_hash = hash.inject({}) { |h,(k,v)| h[symbolize k] = v; h }
        self.new(symbolized_hash)
      end

      def symbolize key
        (key.to_s.gsub(/\s+/,'_').to_sym rescue key) || key
      end
    end
    
    def initialize hash = {}
      super(hash)
    end

    def [] key
      result = super(symbolize(key))
      if result.is_a?(Hash) and not result.is_a?(self.class)
        result = self.class.new(result)
      end
      result
    end
    
    def []= key,value
      k = symbolize(key)
      if value.is_a?(Hash) and self[k].is_a?(Hash)
        self[k].replace(value)
      else
        result = super(k, value)
      end
    end

    def is_a? klazz
      klazz == Hash or super
    end
    
    def deep_copy
      result = self.class.new({})
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
    
    alias_method :_keys, :keys
    def keys
      _keys.reject { |k| self[k].is_a?(Proc) or k.to_s =~ /^@/ }
    end
    
    def method_missing sym, *args, &block
      (name, setter) = sym.to_s.scan(/^(.+?)(=)?$/).flatten
      setter = args.length > 0
      accessor = setter ? args.length == 1 : args.length == 0
      if accessor
        result = setter ? self[name.to_sym] = args[0] : self[name.to_sym]
        if result.nil? and args.length == 0 and block_given?
          result = self[name.to_sym] = self.class.new
        end
        
        if result.is_a?(HashWithStructAccess) and block_given?
          if block.arity == -1
            result.instance_eval(&block)
          else
            yield result
          end
        end
        
        if result.is_a?(Proc) 
          result.call(self)
        else
          result
        end
      else
        super(sym,*args,&block)
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