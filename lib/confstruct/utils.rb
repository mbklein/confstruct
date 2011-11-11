module Kernel
  def eval_or_yield obj, &block
    if block_given?
      if block.arity < 1
        obj.instance_eval(&block)
      else
        block.call(obj)
      end
    else
      obj
    end
  end
end