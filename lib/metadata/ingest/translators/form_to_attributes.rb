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
      @attributes = {}

      for assoc in @form.associations
        translate_association(assoc)
      end
    end

    # Converts a single association (from @form) into a key-value pair in @attributes.  If the
    # association has `internal`, that field will be the value, otherwise `value` is used.
    def translate_association(assoc)
      group_data = @map[assoc.group.to_sym]
      return unless group_data

      attribute = group_data[assoc.type.to_sym]
      return unless attribute

      # Make sure we properly handle destroyed values by forcing them to nil.
      # We keep their state up to this point (and avoid modifying the "live"
      # object) because the user may be using the prior value for something.
      if assoc.marked_for_destruction?
        assoc = assoc.dup
        assoc.internal = nil
        assoc.value = nil
      end

      # This is necessary for web forms where "internal" => "" is a very
      # expected situation we have to handle.  I'm not sure there are valid
      # situations where an internal value of "" is actually worthy of
      # preservation when the "value" field has data.
      value = assoc.internal.blank? ? assoc.value : assoc.internal
      store_attribute_value(attribute, value)
    end

    # Adds the given value to the attribute in @attributes.  If there are no existing values,
    # stores the value as-is.  If the value is an array, the new value is added.  Otherwise, the
    # old value is put into an array with the new value.
    def store_attribute_value(attribute, value)
      current = @attributes[attribute]

      # If there's already a value, we can safely ignore nils - there is
      # currently no use case for storing a nil object alongside valid data.  A
      # value of nil just means the item was marked for destruction, and needs
      # to be set to nil if no other values are present.
      return if current && value.nil?

      case current
        when nil    then @attributes[attribute] = value
        when Array  then @attributes[attribute].push(value)
        else             @attributes[attribute] = [current, value]
      end
    end
  end
end
