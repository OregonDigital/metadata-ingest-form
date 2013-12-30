require "active_model"
require "metadata/ingest/form_backer"

module Metadata
  module Ingest
    # Simple association class for ingest form's nested data
    class Association < FormBacker
      include ActiveModel::Validations

      attr_accessor :type, :value, :group, :internal

      validate :must_have_type_and_value

      def initialize(args = {})
        @group = args[:group]
        @type = args[:type]
        @value = args[:value]
        @internal = args[:internal]
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

      # Allow equivalent objects to be considered equal
      def ==(other)
        for field in [:group, :type, :value, :internal]
          return false unless self.send(field) == other.send(field)
        end
        return true
      end

      # Returns false to conform to ActiveRecord-like specs.  States that this "record" is not
      # going to be destroyed when the parent (ingest form) is saved.
      def marked_for_destruction?
        return false
      end

      # This API is also used to conform to AR specs.  Always returns marked_for_destruction since
      # that's what AR does.
      def _destroy
        return marked_for_destruction?
      end
    end
  end
end
