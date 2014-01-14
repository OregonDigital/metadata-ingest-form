module Metadata::Ingest::Translators

# Helper class for storing some of the state and behaviors explicitly related
# to the data pulled from a single attribute definition.  When a translation
# from an attribute object to an ingest form happens, each attribute definition
# in the map is used to build an instance of this class.
#
# Due to deep delegation needs and translation needs, group, type, and
# attribute aren't sufficient for finding the values on the source object, so
# this class dissects the data further to determine the actual source object
# (in the case of deep delegation, an attribute definition of "foo.bar" means
# the source object is actually `source.foo`) and the attribute (in the prior
# example, that would be "bar" rather than "foo.bar").
class SingleAttributeTranslator
  def initialize(attrs)
    @source = attrs[:source]
    @form = attrs[:form]
    @group = attrs[:group]
    @type = attrs[:type]
    @attribute_definition = attrs[:attribute_definition]
  end

  # For each value in delegated object's values, adds an association to `form`
  # with the given group and type
  def add_associations_to_form
    extract_delegation_data
    for value in object_values
      association = build_association(value)
      @form.add_association(association)
    end
  end

  protected

  # Determines object and attribute used in case deep delegation is necessary
  def extract_delegation_data
    objects = @attribute_definition.to_s.split(".")
    @attribute = objects.pop
    @object = objects.reduce(@source, :send)
  end

  # Returns an array of all values returned by @object.@attribute.  Forces
  # single elements to be in an array to allow consistent use.
  def object_values
    return [*@object.send(@attribute)]
  end

  # Builds a single association with the given data
  def build_association(value)
    association = Metadata::Ingest::Association.new(
      group: @group.to_s,
      type: @type.to_s,
      value: value
    )

    return association
  end
end

end
