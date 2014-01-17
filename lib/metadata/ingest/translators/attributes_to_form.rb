require "metadata/ingest/translators/base"
require "metadata/ingest/translators/single_attribute_translator"

module Metadata::Ingest::Translators
  # Reverse of FormToAttributes - uses the same map format to read attributes
  # and put them into an ingest form object.  Maps should look something like
  # this:
  #
  #     {
  #       group1: {
  #         type1: :attribute1,
  #         type2: :attribute2,
  #         ...
  #       },
  #
  #       group2: {
  #         ...
  #       },
  #
  #       ...
  #     }
  #
  # In this example, `object.attribute1 = ["foo", "bar"]` would be built on the
  # form as two associations, both with a group of "group1" and a type of
  # "type1".
  #
  # Attributes that aren't mapped are ignored, so it's important to map
  # everything that should be presented on the form (or else write a
  # post-processor of your own to pull the unmapped data somewhere).
  class AttributesToForm < Base
    attr_accessor :source
    attr_writer :single_attribute_translator

    class << self
      def from(source, single_attribute_translator = nil)
        translator = self.new
        translator.source = source
        return translator
      end
    end

    # Returns the class for building a single-attribute translator, defaulting
    # to the simple built-in class
    def single_attribute_translator
      return @single_attribute_translator || Metadata::Ingest::Translators::SingleAttributeTranslator
    end

    # Sets the single attribute translator, returning self for method chaining
    def using_translator(attr_trans)
      @single_attribute_translator = attr_trans
      return self
    end

    # Converts @source to an ingest form
    def to(form)
      @form = form
      for group, type_attr_map in self.class.map
        for type, attr_definition in type_attr_map
          setup_form(group, type, attr_definition)
        end
      end
    end

    # Sets up translation state instance to hold various attributes that need to be passed around,
    # and calls helpers to build the necessary associations and attach them to the form.
    def setup_form(group, type, attr_definition)
      attr_trans = single_attribute_translator.new(
        source: @source,
        form: @form,
        group: group,
        type: type,
        attribute_definition: attr_definition
      )

      attr_trans.add_associations_to_form
    end
  end
end
