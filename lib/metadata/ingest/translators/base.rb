# Presumably all translators will need to know about the form
require "metadata/ingest/form"

class InterfaceNotImplementedError < NoMethodError; end

module Metadata::Ingest::Translators
  # Defines the core translation interface to which all translators should adhere.  Might be used
  # someday for factory-ifying things, but at a minimum sticking to this ensures consistency.
  class Base
    class << self
      # Some kind of structure should go here to define groups, types, and how that translates
      # between the ingest form and whatever other object is being handled.
      def map=(val)
        @map = val
      end

      def map
        return @map
      end

      # Returns an array of group strings suitable for use in Metadata::Ingest::Form.internal_groups=
      def form_groups
        raise InterfaceNotImplementedError.new
      end

      # Returns a translator instance for the given input
      def from(input)
        raise InterfaceNotImplementedError.new
      end
    end

    # Translates the input object and sets translated data on the output object
    def to(output)
      raise InterfaceNotImplementedError.new
    end
  end
end
