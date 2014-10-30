require "active_model"
require "metadata/ingest/form_backer"

module Metadata
  module Ingest
    # Simple association class for ingest form's nested data.  Attributes:
    # * `group`: Human interface element for grouping similar data - titles,
    #   subjects, etc
    # * `type`: More specific data for what this data means within a group -
    #   main title, alternate title, etc
    # * `value`: Human-friendly value
    # * `internal`: Internal representation of the value, if applicable
    #
    # Type and value must always be present for a valid object.  Group isn't
    # strictly required, but it won't make sense for translation without a
    # group.
    #
    # Internal data is optional, and only used for complex data that requires a
    # human-readable component.  For instance, on a web form an autocomplete
    # could show the user "Food industry and trade" when "food" was typed in.
    # On selection and save, the form would send "Food industry and trade" as
    # `value`, but "http://id.loc.gov/authorities/subjects/sh85050282" would be
    # sent as `internal`.  Using the standard form-to-attribute translator, the
    # object would never see the human-friendly term and only receive the URI.
    #
    # When converting from object to form (for editing or even display), the
    # translator would need to be able to recognize that
    # "http://id.loc.gov/authorities/subjects/sh85050282" isn't a
    # human-friendly value so it could put that into `internal` and put "Food
    # industry and trade" into `value`.
    class Association < FormBacker
      include ActiveModel::Validations

      attr_accessor :type, :value, :group, :internal, :persisted, :manual_errors

      validate :must_have_type_and_value
      validate :must_not_have_manual_errors

      def initialize(args = {})
        @group = args[:group]
        @type = args[:type]
        @value = args[:value]
        @internal = args[:internal]
        @destroy = "1" == args[:_destroy]
        @manual_errors = ActiveModel::Errors.new(self)
      end

      # True if both type and value are empty.  In that state, the object represents a placeholder for
      # a given top-level group's data.
      def blank?
        return @type.blank? && @value.blank?
      end

      # Validation method which rejects blank type or value, but allows both to be blank as that
      # indicates empty data, not an error
      def must_have_type_and_value
        return if blank?

        errors.add(:type, "cannot be blank") if @type.blank?
        errors.add(:value, "cannot be blank") if @value.blank?
      end

      # Since association and delegated object's attributes are completely
      # separate, we need a way to say that a given association is invalid from
      # an external source, such as the translator.  This ensures we can
      # properly display errors on a form without tightly coupling the form and
      # the delegated asset.
      #
      # This is unfortunately necessary to be a separate validity check as
      # calls to `valid?` automatically empty the errors object.  i.e., caller
      # can't just set `association.errors.add(attr, msg)` and then check
      # `valid?` in a controller or something.
      def must_not_have_manual_errors
        return if manual_errors.empty?

        for attr, msg in manual_errors
          errors.add(attr, msg)
        end
      end

      def persisted?
        return @persisted
      end

      # Allow equivalent objects to be considered equal
      def ==(other)
        for field in [:group, :type, :value, :internal]
          return false unless self.send(field) == other.send(field)
        end
        return true
      end
    end
  end
end
