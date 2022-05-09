# frozen_string_literal: true

require "minitest_config"

describe Cartage::Core do
  let(:subject) {
    Class.new.tap do |klass|
      klass.class_eval do
        extend Cartage::Core

        class << self
          public :attr_reader_with_default
          public :attr_writer_with_transform
          public :attr_accessor_with_default
        end
      end
    end
  }
  let(:object) { subject.new }

  describe "attr_reader_with_default" do
    it "fails without a default" do
      assert_raises_with_message ArgumentError, "No default provided." do
        subject.attr_reader_with_default :answer
      end
    end

    it "fails with too many defaults" do
      assert_raises_with_message ArgumentError, "Too many defaults provided." do
        subject.attr_reader_with_default :answer, 42, &-> { 42 }
      end
    end

    it "defines default and reader methods when given a value" do
      subject.attr_reader_with_default :answer, 42
      assert_respond_to object, :answer
      assert_equal 42, object.answer

      assert_respond_to object, :default_answer
      assert_equal 42, object.default_answer
    end

    it "defines default and reader methods when given a block" do
      subject.attr_reader_with_default :answer do
        42
      end

      assert_respond_to object, :answer
      assert_equal 42, object.answer

      assert_respond_to object, :default_answer
      assert_equal 42, object.default_answer
    end

    it "memoizes the default value" do
      subject.attr_reader_with_default :favourite_colour, "blue"
      assert_same object.default_favourite_colour, object.default_favourite_colour
    end
  end

  describe "attr_writer_with_transform" do
    it "fails without a transform" do
      assert_raises_with_message ArgumentError, "No transform provided." do
        subject.attr_writer_with_transform :answer
      end
    end

    it "fails with too many transforms" do
      assert_raises_with_message ArgumentError, "Too many transforms provided." do
        subject.attr_writer_with_transform :answer, 42, &-> { 42 }
      end
    end

    it "fails if the transform is not callable" do
      assert_raises_with_message ArgumentError, "Transform is not callable." do
        subject.attr_writer_with_transform :answer, 42
      end
    end

    it "defines a writer method when given a symbol" do
      subject.attr_writer_with_transform :answer, :to_s
      assert_respond_to object, :answer=
      object.answer = 42
      assert_equal "42", object.instance_variable_get(:@answer)
    end

    it "defines a writer method when given a callable" do
      subject.attr_writer_with_transform :answer, ->(v) { v.to_s }
      assert_respond_to object, :answer=
      object.answer = 42
      assert_equal "42", object.instance_variable_get(:@answer)
    end

    it "defines a writer method when given a block" do
      subject.attr_writer_with_transform :answer do |v|
        String(v)
      end
      assert_respond_to object, :answer=
      object.answer = 42
      assert_equal "42", object.instance_variable_get(:@answer)
    end
  end

  describe "attr_accessor_with_default" do
    it "fails without a default" do
      assert_raises_with_message ArgumentError, "No default provided." do
        subject.attr_accessor_with_default :answer
      end
    end

    it "defines a default, reader, and writer methods when given a value" do
      subject.attr_accessor_with_default :answer, default: 42

      assert_respond_to object, :answer
      assert_respond_to object, :default_answer
      assert_respond_to object, :answer=

      object.answer = 21
      assert_equal 21, object.answer
      assert_equal 42, object.default_answer
    end

    it "defines a default, reader, and writer methods when given a block" do
      subject.attr_accessor_with_default :answer do
        42
      end

      assert_respond_to object, :answer
      assert_respond_to object, :default_answer
      assert_respond_to object, :answer=

      object.answer = 21
      assert_equal 21, object.answer
      assert_equal 42, object.default_answer
    end

    it "memoizes the default value" do
      subject.attr_accessor_with_default :favourite_colour, default: "blue"
      assert_same object.favourite_colour, object.favourite_colour
    end

    it "fails if transform is not callable" do
      assert_raises_with_message ArgumentError, "Transform is not callable." do
        subject.attr_accessor_with_default :answer, default: 42, transform: 42
      end
    end

    it "accepts a symbol for transform" do
      subject.attr_accessor_with_default :answer, default: 42, transform: :to_s

      assert_respond_to object, :answer
      assert_respond_to object, :default_answer
      assert_respond_to object, :answer=

      assert_equal 42, object.answer
      object.answer = 21
      assert_equal "21", object.answer
    end

    it "accepts a callable for transform" do
      subject.attr_accessor_with_default :answer,
        default: 42, transform: ->(v) { v.to_s }
      assert_respond_to object, :answer
      assert_respond_to object, :default_answer
      assert_respond_to object, :answer=

      assert_equal 42, object.answer
      object.answer = 21
      assert_equal "21", object.answer
    end
  end
end
