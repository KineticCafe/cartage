# frozen_string_literal: true

# :nocov:
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
  # An implementation of #dig for Ruby pre-2.3. Based originally on
  # {Invoca/ruby_dig}[https://github.com/Invoca/ruby_dig] with some inspiration
  # from {jrochkind/dig_rb}[https://github.com/jrochkind/dig_rb].
  module Cartage::Dig #:nodoc:
    def dig(key, *rest)
      value = self[key]

      if value.nil? || rest.empty?
        value
      elsif value.respond_to?(:dig)
        value.dig(*rest)
      else
        fail TypeError, "#{value.class} does not have #dig method"
      end
    end
  end

  ::Array.send(:include, Cartage::Dig) unless ::Array.public_method_defined?(:dig)
  ::Hash.send(:include, Cartage::Dig) unless ::Hash.public_method_defined?(:dig)

  unless ::Struct.public_method_defined?(:dig)
    # Struct gets a different override.
    module Cartage::StructDig # :nodoc:
      include Cartage::Dig

      # This override is necessary because <tt>Struct.new(:a).new(1)[0]</tt> is
      # *legal*. So we don't just care about NameError, but IndexError as well.
      def dig(name, *rest)
        super
      rescue IndexError, NameError
        nil
      end
    end

    ::Struct.send(:include, Cartage::StructDig)
  end

  unless ::OpenStruct.public_method_defined?(:dig)
    # OpenStruct gets a different override.
    module Cartage::OpenStructDig # :nodoc:
      def dig(name, *rest)
        @table.dig(name.to_sym, *rest)
      rescue NoMethodError
        raise TypeError, "#{name} is not a symbol nor a string"
      end
    end

    ::OpenStruct.send(:include, Cartage::OpenStructDig)
  end
end

unless Pathname.public_method_defined?(:write)
  ##
  module Cartage::PathnameWrite #:nodoc:
    def write(*args)
      IO.write(to_s, *args)
    end
  end

  ::Pathname.send(:include, Cartage::PathnameWrite)
end
# :nocov:
