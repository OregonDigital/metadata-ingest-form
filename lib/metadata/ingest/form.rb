require "active_model"
require "metadata/ingest/form_backer"
require "metadata/ingest/association"

module Metadata
  module Ingest
    # Form-backing object for ingesting generic data
    class Form < FormBacker
      # Container for raw RDF data stored as an array of hashes for easy use on forms (currently used
      # for statements which didn't match the digital object's subject)
      attr_reader :raw_statements

      include ActiveModel::Validations

      validate :children_must_be_valid

      class << self
        # This makes our object work better with various gems, particularly cocoon.  This probably
        # doesn't belong here, but I know this is necessary within the context of the whole project.
        #
        # The code here is basically telling cocoon (and any other Railsy gems that care to ask) that
        # it has no explicit associations (has_many, for instance).  Being non-ActiveRecord, this is
        # the easiest and safest approach.
        def reflect_on_association(association)
          return nil
        end
      end

      def initialize(attr = {})
        @raw_statements = []
        @data = {}
        @empty = true
        self.attributes = attr if attr
      end

      # Assigns list of groups for ingest forms to use.  Please note:
      # - This should only be set ONCE unless you REALLY know what you're doing
      # - The groups should be strings, not symbols
      # - Groups should be singular - "title", not "titles" - in order to work with the magic in
      #   the dynamic_method_map function.
      def internal_groups=(val)
        @internal_groups = val
      end

      def internal_groups
        @internal_groups ||= []
        return @internal_groups
      end

      def groups
        return internal_groups + ["unmapped_association"]
      end

      def valid_group?(group)
        return groups.include?(group)
      end

      # Helps us manage the two places we need to expose our dynamic methods.  Returns the method
      # name and arguments to pass it, suitable for a send call, if the dynamic method name is
      # valid.  Returns false on method names not handled.
      def dynamic_method_map(method, *args)
        if method.to_s =~ /^build_(.*)$/
          group = $1
          return false if !valid_group?(group)
          return [:_build_group, group, args.first || {}]
        end

        if method.to_s =~ /^(.*)_attributes=$/
          group = $1.singularize
          return false if group.pluralize != $1
          return false if !valid_group?(group)
          return [:_build_groups, group, args.first || {}]
        end

        group = method.to_s.singularize
        if valid_group?(group) && group.pluralize == method.to_s
          return [:_get_group, group]
        end

        return false
      end

      # Sets internal Metadata::Ingest::Association objects for all attributes found that match
      # the pattern "*_attributes".  The normal getter methods will only look for valid groups,
      # ensuring some sanity here.  We allow for anything to be set since valid groups are dynamic
      # per instance, and aren't necessarily set before this call (e.g., if `.new` is called).
      def attributes=(attributes = {})
        # Check for unknown data
        @raw_statements = attributes.delete("raw_statements") if attributes["raw_statements"]

        # Check for *_attributes keys for building groups
        for attr, values in attributes
          if attr =~ /\A(\w+)_attributes\Z/
            _build_groups($1.singularize, values)
          end
        end
      end

      # If we don't appear to respond to a method, check the dynamic method map data before really
      # reporting false
      def respond_to?(method, include_private = false)
        return super || !!dynamic_method_map(method)
      end

      def method_missing(method, *args)
        # Check for dynamic method responding magic
        method_info = dynamic_method_map(method, *args)
        return super unless method_info

        return self.send(*method_info)
      end

      # Builds an Ingest::Association object and appends it to the array in @data[group]
      def _build_group(group, attrs)
        @empty = false
        attrs.symbolize_keys!
        attrs[:group] = group
        obj = Ingest::Association.new(attrs)
        _get_group(group) << obj
        return obj
      end

      # Scrubs all items in the given group and adds objects for each attribute hash given
      def _build_groups(group, multi_attrs)
        @data[group] = []
        for key, attrs in multi_attrs
          _build_group(group, attrs)
        end

        return @data[group]
      end

      # Returns all items for the given group in the same way a typical association data would be
      # returned via `obj.items`
      def _get_group(group)
        @data[group] ||= []
        return @data[group]
      end

      # Iterates over all valid groups' associations, returning an array
      def associations
        objs = []
        for group in groups
          for item in _get_group(group)
            objs.push(item)
          end
        end

        # Freeze the array so it's clear this isn't what one might expect in terms of a mutable array
        return objs.freeze
      end

      # Attaches the given association to this object by storing its data on the appropriate group
      def add_association(assoc)
        @empty = false
        _get_group(assoc.group) << assoc
        return assoc
      end

      # Attaches the given raw statement data to the list of unknown raw statement data.  `statement`
      # is expected to act like RDF::Statement - responds to #subject, #predicate, and #object.
      def add_raw_statement(statement)
        @raw_statements.push({
          :subject    => statement.subject.to_s,
          :predicate  => statement.predicate.to_s,
          :object     => statement.object.to_s
        })
      end

      # Returns a boolean representing whether the object is empty or not.  An object that's never had
      # *any* data manipulation is considered empty, even though technically one could add empty items
      # to a group.
      def empty?
        return !!@empty
      end

      # Validates children, carrying their errors up so this object isn't valid if children aren't
      def children_must_be_valid
        for obj in associations
          next if obj.valid?
          obj.errors.each do |attr, msg|
            errors.add(:"#{obj.group}.#{attr}", msg)
          end
        end
      end
    end
  end
end
