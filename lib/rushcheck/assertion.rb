# = assertion.rb
# this file provides a class Assertion for random testing.

require 'rushcheck/error'
require 'rushcheck/gen'
require 'rushcheck/guard'
require 'rushcheck/property'
require 'rushcheck/result'
require 'rushcheck/testable'

module RushCheck

  # Assertion class is one of main features of RushCheck.
  # You can write a testcase for random testing as follows:
  #
  #   RushCheck::Assertion.new(Integer, String) do |n, s|
  #     RushCheck::guard { precondition }
  #     body
  #   end.check
  #
  # The return value of the body of testcase should be
  # true or false and checked by the method 'check'.
  #
  # Note that the number of arguments in the block must be
  # equal to the number of arguments of Assertion.new.
  # Otherwise an exception is raised.
  #
  # See also the tutorial and several examples.

  class Assertion

    include RushCheck::InternalError
    include RushCheck::Testable

    # The body in the test as a block
    attr_reader :body

    # Create a random test code. The argument _xs_ should be
    # classes. The block _f_ takes variables as same as the
    # number of _xs_. This should be return true or false.
    def initialize(*xs, &f)

      err_n = [ "Incorrect number of variables:",
                "( #{xs.length} for #{f.arity} )" ].join(' ')
      if f.arity == -1
        raise(RushCheckError, err_n) # unless xs.empty?
      elsif xs.length != f.arity
        raise(RushCheckError, err_n)
      end

      xs.each do |x|
        err_c = ["Illegal variable which is not Class:",
                 x.inspect].join(' ')
        raise(RushCheckError, err_c) unless x.class === Class
      end

      @inputs = xs[0..(f.arity - 1)]
      @body = f
    end

    def property #:nodoc:
      g = RushCheck::Gen.new do |n, r|
        r2 = r
        if @inputs
        then
          @inputs.map do |c|
            r1, r2 = r2.split
            c.arbitrary.value(n, r1)
          end
        else
          []
        end
      end.bind do |args|
        test = begin
                 r = @body.call(*args)
                 unless r == true || r == false
                   err = ["The body of Assertion.new should be",
                          "true or false, but:",
                          test.inspect].join(' ')
                   raise(RushCheckError, err)
                 end
                 r
               rescue Exception => ex
                 case ex
                 when RushCheckError
                   raise ex
                 when RushCheck::GuardException
                   RushCheck::Result.new(nil)
                 else
                   err = "Unexpected exception: #{ex.inspect}\n" +
                     ex.backtrace.join("\n")
                   RushCheck::Result.new(false, [], [err])
                 end
               end
        # not use ensure here because ensure clause
        # does not return values
        test.property.gen.fmap do |res|
          res.arguments << args.inspect
          res
        end
      end

      RushCheck::Property.new(g)
    end

  end

end
