# frozen_string_literal: true

##
class Cartage
  # Extensions for us to use to help define Cartage with its attr_readers with
  # defaults and attr_writers with transforms.
  module Core # :nodoc:
    private

    # Define an attr_reader with a memoized default value. The +default+ is
    # required and can be provided either as a callable (such as a proc), a
    # value, or as a block.
    #
    # Note that the default will be called if and only if the instance variable
    # of the same name has not been set in any other way.
    #
    # ==== Example
    #
    #    # Create :answer and :default_answer.
    #    attr_reader_with_default :answer, -> { 42 }
    #    # Does the same thing
    #    attr_reader_with_default :answer do
    #      42
    #    end
    #    # Does the same thing
    #    attr_reader_with_default :answer, 42
    def attr_reader_with_default(name, default = nil, &block)
      fail ArgumentError, "No default provided." unless default || block
      fail ArgumentError, "Too many defaults provided." if default && block

      default_ivar = :"@default_#{name}"
      default_name = :"default_#{name}"

      ivar = :"@#{name}"
      name = name.to_sym

      define_method(name) do
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          send(default_name)
        end
      end

      dblk = if default.respond_to?(:call)
        default
      else
        block || -> { default }
      end

      define_method(default_name) do
        if instance_variable_defined?(default_ivar)
          instance_variable_get(default_ivar)
        else
          instance_variable_set(default_ivar, instance_exec(&dblk))
        end
      end
    end

    # Define an attr_writer with a transform that transforms the provided
    # value. Conceptually, this is the same as defining an assignment method
    # that performs the transform on the provided value.
    #
    # The +transform+ may be provided as a callable (such as a proc), an object
    # that responds to #to_proc (such as a Symbol), or a block.
    def attr_writer_with_transform(name, transform = nil, &block)
      fail ArgumentError, "No transform provided." unless transform || block
      fail ArgumentError, "Too many transforms provided." if transform && block

      tblk = if transform.respond_to?(:call)
        transform
      elsif transform.respond_to?(:to_proc)
        transform.to_proc
      elsif block
        block
      else
        fail ArgumentError, "Transform is not callable."
      end

      define_method(:"#{name}=") do |v|
        instance_variable_set(:"@#{name}", tblk.call(v))
      end
    end

    # Define an attr_accessor with a default attr_reader. The default is
    # required and must be provided either using the +default+ parameter or a
    # block.
    #
    # Optionally, a +transform+ block can be used to provide a transformation
    # executed on assignment. (This will call #attr_writer_with_transform if
    # provided, #attr_writer if not.)
    #
    # ==== Example
    #
    #   # Creates :name, :name=, :default_name methods.
    #   attr_accessor_with_default :name do
    #     File.basename(repo_url, '.git')
    #   end
    def attr_accessor_with_default(name, default: nil, transform: nil, &block)
      attr_reader_with_default name, default || block
      if transform
        attr_writer_with_transform name, transform
      else
        attr_writer name
      end
    end
  end

  extend Core
end

require_relative "backport"
