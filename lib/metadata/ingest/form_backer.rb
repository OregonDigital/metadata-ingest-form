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
    end
  end
end
