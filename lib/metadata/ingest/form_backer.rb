require "active_model"

module Metadata
  module Ingest
    # Base class for form-backing objects.  Gives simplest-case, default behaviors for form_for
    # blocks in views.
    class FormBacker
      # ActiveModel plumbing to make `form_for` work
      extend ActiveModel::Naming
      include ActiveModel::Conversion

      attr_accessor :id

      # Returns whether or not the object is stored somewhere
      def persisted?
        return @id != nil
      end

      def new_record?
        return !persisted?
      end

      # Returns whether or not this record should be destroyed when the parent
      # (ingest form) is "saved".  This method can be used by translator
      # classes, and is necessary to conform to ActiveRecord-like specs.
      def marked_for_destruction?
        return @destroy
      end

      # This API is also used to conform to AR specs.  Always returns
      # marked_for_destruction since that's what AR does.
      def _destroy
        return marked_for_destruction?
      end

      # Marks this as being destroyed - primarily for marking associated data
      # as needing to be deleted
      def destroy!
        @destroy = true
      end
    end
  end
end
