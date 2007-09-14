require File.dirname(__FILE__) + "/test_helper.rb"

test_class(:TestClassSide)

# In Ruby there are multiple ways of defining behaviour on the class side. That
# are messages that are send to the class, not on the instance. Class side 
# behaviour is often useful for functional methods, i.e. methods that do not
# rely on inner state and have no side effects. Mathematical functions have 
# these characteristics - that is where the name probably comes from.


# Using def self.method_name
# ==========================

# The simpliest way of defining class side behaviour is prepending self. to the
# method definition. This way, the method is attached to the surrounding class 
# and not instance. A simple example:

class SimpleMath
  def self.pi
    3.14159265
  end
end

example do
  result_of(SimpleMath.pi) == 3.14159265
end


# Using class << self
# ===================

# When you are having lots of class side methods as well as instance side ones,
# it can be difficult to spot the little self. in front of the method name.
# Probably you like to group them more explicitly. You could use Ruby's
# eigenclass principle for that. It will look like the following:

class SimpleMath
  class << self
    def e
      2.71828183
    end
  end
end

example do
  result_of(SimpleMath.e) == 2.71828183 
end


# Using a module
# ==============

# For even more encapsulation you could also use modules and extend the class 
# definition with them. I am using extend here on purpose. Module's include
# method adds the behaviour to the instance side, extend to the class side.

class SimpleMath
  module ClassMethods
    def golden_ratio
      1.6180339887
    end
  end

  extend ClassMethods
end

example do
  result_of(SimpleMath.golden_ratio) == 1.6180339887 
end

# The last method is e.g. often used in the web framework Ruby on Rails. Often
# a variation of it is used to define class and instance side behaviour for
# mixin modules

module MathMixin
  def counter
    @counter ||= 0
    @counter += 1
  end

  module ClassMethods
    def sqrt(x)
      x ** 0.5
    end
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
  end
end

class SimpleMath
  include MathMixin
end

example do
  result_of(SimpleMath.sqrt(4)) == 2

  my_simple_math = SimpleMath.new
  result_of(my_simple_math.counter) == 1
  result_of(my_simple_math.counter) == 2
end

# This is regarded as the most elegant way of defining class and instance 
# methods for a mixin module. And the basic functionality is the same as in the
# previous example.

# After we now know how to define class side behaviour, everybody is curious
# to know how to extend this behaviour using context-oriented programming and
# ContextR.
#
# Additionial, context-dependent behaviour is defined in modules. These modules
# are then attached to the class with a selector representing the layer, in
# which the behaviour should reside. For examples on the instance side
# have a look at the bottom of test_introduction.
#
# Let's how we can achieve the same on the class side for each of the different
# methods of defining class side behaviour.


# Using def self.method_name
# ==========================

# Okay, we won't get rid of the modules, used to encapsulate the 
# context-dependent behaviour, so the extension is a bit noisier, than the 
# basic notation.

class SimpleMath
  module AccessControlMethods
    def pi
      "You are not allowed to access this method"
    end
  end

  extend AccessControlMethods => :access_control
end

# But we can use the same principles, like we did for the instance side. Simply
# use a hash to tell extend, that the module should only be used in a certain
# layer.

example do
  result_of(SimpleMath.pi) == 3.14159265

  ContextR::with_layer :access_control do
    result_of(SimpleMath.pi) == "You are not allowed to access this method" 
  end
end


# Using class << self
# ===================

# When your using the eigenclass, you are able to use to good old include to
# manage the extension. But nobody stops you if you fell in love with extend.

class SimpleMath
  class << self
    module EnglishMethods
      def e
        "Euler's constant"
      end
    end
    include EnglishMethods => :english
  end

  module GermanMethods
    def e
      "Eulersche Zahl"
    end
  end
  extend GermanMethods => :german
end

example do
  result_of(SimpleMath.e) == 2.71828183 

  ContextR::with_layer :german do
    result_of(SimpleMath.e) == "Eulersche Zahl" 
  end
  ContextR::with_layer :english do
    result_of(SimpleMath.e) == "Euler's constant" 
  end
end


# Using a module
# ==============

# Hey, this is what we did all the time, so it is only natural to have the same
# syntax to extend a class using in module for context-dependent behaviour. But
# for the sake of completeness, I will attach another example.

class SimpleMath
  module ExactComputationMethods
    def golden_ratio
      sleep(0.01) # In real life this would take a bit longer, 
                  # but I don't have the time.
      1.6180339887_4989484820_4586834365_6381177203_0917980576 
    end
  end

  extend ExactComputationMethods => :exact_computation
end

example do
  result_of(SimpleMath.golden_ratio) == 1.6180339887

  ContextR::with_layer :exact_computation do
    result_of(SimpleMath.golden_ratio) == 
                      1.6180339887_4989484820_4586834365_6381177203_0917980576 
  end
end


# Conclusion
# ==========

# In general, there are two options to define context-dependent class side
# behaviour. Use include in the eigenclass or use extend anywhere else. Both
# options result in the same behaviour, just like the different options in 
# plain ruby look different, but have the same effect.
#
# The programmer is free to use, whatever suites best. This is still Ruby.
