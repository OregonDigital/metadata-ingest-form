# Presumably all translators will need to know about the form
require "metadata/ingest/form"

class InterfaceNotImplementedError < NoMethodError; end

module Metadata::Ingest::Translators
  # Defines the core translation interface to which all translators should adhere.  Might be used
  # someday for factory-ifying things, but at a minimum sticking to this ensures consistency.
  class Base
    class << self
      # Returns a translator instance for the given input
      def from(input)
        raise InterfaceNotImplementedError.new
      end
    end

    # Sets the translation map, which should be some kind of structure to
    # define groups, types, and how that translates between the ingest form and
    # whatever other object is being handled.
    def using_map(map)
      @map = map
      return self
    end

    # Translates the input object and sets translated data on the output object
    def to(output)
      raise InterfaceNotImplementedError.new
    end
  end
end
