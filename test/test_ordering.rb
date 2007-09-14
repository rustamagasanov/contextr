require File.dirname(__FILE__) + "/test_helper.rb"

test_class(:TestOrdering)

# This document tries to demonstrate the invocation order within 
# context-specific method calls. There are two cases where this is relevant:
# 1. There is more than one layer active, that extends the method.
# 2. There is more than one module in a single layer that extends the method.
#
# Unfortunately I could not find any relevant example that clearly demonstrates
# this behaviour. Therefore I will use foo bar code. But I think it is still
# easy to get the message.

# 1. Multiple active layers
# =========================

class OrderingTest
  def test_method 
    "base_method"
  end

  module FooMethods
    def test_method
      "foo_before #{yield(:next)} foo_after"
    end
  end
  module BarMethods
    def test_method
      "bar_before #{yield(:next)} bar_after"
    end
  end

  include FooMethods => :foo
  include BarMethods => :bar
end

# When multiple layers extend a single method, the order of activation 
# determines the order of execution.

example do
  instance = OrderingTest.new
  result_of(instance.test_method) == "base_method"

  ContextR::with_layer :foo do
    result_of(instance.test_method) == "foo_before base_method foo_after"
  end
  ContextR::with_layer :bar do
    result_of(instance.test_method) == "bar_before base_method bar_after"
  end

  ContextR::with_layer :bar, :foo do
    result_of(instance.test_method) == 
                      "bar_before foo_before base_method foo_after bar_after"
  end

  ContextR::with_layer :bar do
    ContextR::with_layer :foo do
      result_of(instance.test_method) == 
                      "bar_before foo_before base_method foo_after bar_after"
    end
  end

  ContextR::with_layer :foo, :bar do
    result_of(instance.test_method) == 
                      "foo_before bar_before base_method bar_after foo_after"
  end

  ContextR::with_layer :foo do
    ContextR::with_layer :bar do
      result_of(instance.test_method) == 
                      "foo_before bar_before base_method bar_after foo_after"
    end
  end
end

# As you can see, the innermost layer activation provides the innermost method
# definition. It is not important, whether the layers were activated at once
# or one after the other.
#
# Activating and already active layer may update the execution order. The outer
# activation is hidden, but is restored again after leaving the block.

example do
  instance = OrderingTest.new

  ContextR::with_layer :bar, :foo do
    result_of(instance.test_method) == 
                      "bar_before foo_before base_method foo_after bar_after"

    ContextR::with_layer :bar do
      result_of(instance.test_method) == 
                      "foo_before bar_before base_method bar_after foo_after"
    end

    result_of(instance.test_method) == 
                      "bar_before foo_before base_method foo_after bar_after"
  end
end


# Multiple modules per layer and class
# ====================================

# It is also possible to have more than one module define the context-dependent
# behaviour of a class. In this case it may also happen, that multiple modules
# extend the same method definition.
#
# In this case we can reuse or already defined class and modules. This time
# we include them into the same layer and see what happens.

class OrderingTest
  include FooMethods => :foo_bar
  include BarMethods => :foo_bar
end

example do
  instance = OrderingTest.new
  result_of(instance.test_method) == "base_method"

  ContextR::with_layer :foo_bar do
    result_of(instance.test_method) == 
                      "bar_before foo_before base_method foo_after bar_after"
  end
end

# This time the last inclusion defines the outermost method. This can be again
# changed. After repeating an inclusion the ordering is updated.

example do
  class OrderingTest
    include FooMethods => :foo_bar
  end

  instance = OrderingTest.new
  result_of(instance.test_method) == "base_method"

  ContextR::with_layer :foo_bar do
    result_of(instance.test_method) == 
                      "foo_before bar_before base_method bar_after foo_after"
  end
end

# These should be all case where ordering matters. If you are aware of the
# two basic rules, everything should work as expected. In an ideal world the
# the execution order would not be important. But hey, this is not the ideal
# world, so you better know.
