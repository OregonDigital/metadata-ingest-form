require "metadata/ingest/translators/base"

module Metadata::Ingest::Translators
  # Simple delegator using group and type to map to an attribute.  Maps should look something like
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
  # In this example, anything on the ingest form in group 1 with type 1 selected would be sent to
  # the output object's `attribute1` method.  For simplicity, if only one object is present, it is
  # sent as-is, whereas an array of objects is sent if there are multiple values for the same group
  # and type combination.
  #
  # Attributes on the form that are not mapped end up being ignored.  As such, there is no use here
  # of raw statements or unmapped association types - given those will be read-only on the form
  # anyway, it wouldn't make sense to assign them here.
  class FormToAttributes < Base
    attr_accessor :form

    class << self
      def form_groups
        return @map.keys.collect {|key| key.to_s}
      end

      def from(ingest_form)
        translator = self.new
        translator.form = ingest_form
        return translator
      end
    end

    # Converts @form to attributes assigned to output object
    def to(output)
      build_translated_attribute_hash

      for attr, val in @attributes
        objects = attr.to_s.split(".")
        attribute = objects.pop
        objects.reduce(output, :send).send("#{attribute}=", val)
      end
    end

    # Converts @form's associations to a hash of attributes and values
    def build_translated_attribute_hash
      map = self.class.map
      @attributes = {}

      for assoc in @form.associations
        translate_association(assoc)
      end
    end

    # Converts a single association (from @form) into a key-value pair in @attributes.  If the
    # association has `internal`, that field will be the value, otherwise `value` is used.
    def translate_association(assoc)
      group_data = self.class.map[assoc.group.to_sym]
      return unless group_data

      attribute = group_data[assoc.type.to_sym]
      return unless attribute

      store_attribute_value(attribute, assoc.internal || assoc.value)
    end

    # Adds the given value to the attribute in @attributes.  If there are no existing values,
    # stores the value as-is.  If the value is an array, the new value is added.  Otherwise, the
    # old value is put into an array with the new value.
    def store_attribute_value(attribute, value)
      current = @attributes[attribute]

      case current
        when nil    then @attributes[attribute] = value
        when Array  then @attributes[attribute].push(value)
        else             @attributes[attribute] = [current, value]
      end
    end
  end
end
