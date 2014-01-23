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

      for attr, associations in @attributes
        objects = attr.to_s.split(".")
        attribute = objects.pop
        object = objects.reduce(output, :send)
        store_associations_on_object(object, attribute, associations)
      end
    end

    # Converts @form's associations to a hash of attributes and values
    def build_translated_attribute_hash
      @attributes = {}

      for assoc in @form.associations
        translate_association(assoc)
      end
    end

    # Extracts the attribute definition for a given association
    def attribute_lookup(assoc)
      group_data = @map[assoc.group.to_sym]
      return nil unless group_data

      attribute = group_data[assoc.type.to_sym]
      return attribute
    end

    # Maps an association to the attribute its data will be tied
    def translate_association(assoc)
      attribute = attribute_lookup(assoc)
      return unless attribute

      # Make sure we properly handle destroyed values by forcing them to an
      # empty association.  We keep their state up to this point because the
      # caller may be using the prior value for something.
      if assoc.marked_for_destruction?
        assoc = Metadata::Ingest::Association.new
      end

      add_association_to_attribute_map(attribute, assoc)
    end

    # Adds the given association to an array of associations for the given
    # attribute
    def add_association_to_attribute_map(attribute, assoc)
      current = @attributes[attribute]

      # If there's already a value, we can safely ignore the empty association
      return if current && assoc.blank?

      case current
        when nil    then @attributes[attribute] = [assoc]
        when Array  then @attributes[attribute].push(assoc)
      end
    end

    # Stores all association data on the object at the given attribute.
    # Associations with internal data use that instead of value.  If only one
    # association is present, it is extracted from the array and stored as-is.
    def store_associations_on_object(object, attribute, associations)
      values = associations.collect do |assoc|
        assoc.internal.blank? ? assoc.value : assoc.internal
      end

      # Clean up values
      values.compact!
      case values.length
        when 0 then values = nil
        when 1 then values = values.first
      end

      object.send("#{attribute}=", values)
    end
  end
end
