# Metadata::Ingest::Form

Provides form-backing objects for metadata models

An attempt to provide simpler access to complex back-end data by telling the
form how to group similar fields into a multiple field entity.  This only
provides a model for doing this and a simple two-way attribute-delegation
translator.  No UI elements are provided, and complex translation is left as an
exercise to the reader.

## READ THIS!

This project is a port from the old prototype code we built.  It might not make
sense outside the OregonDigital project.

The goal is to extract the old code to separate it from some of the hard-coded
rules which were applied in the prototype and see what components can be put
into libraries vs. having to live back in the application itself.

## Installation

Add this line to your application's Gemfile:

    gem 'metadata-ingest-form', :git => "git://github.com/OregonDigital/metadata-ingest-form.git"

(Eventually this will be a real gem and you can drop the `:git` repository
link)

And then execute:

    $ bundle

## Usage

`Metadata::Ingest::Form` is the top-level FBO (Form-backing object) class.  At
its core, it's just a class that allows configurable attributes to be set, and
happens to work with a Rails form builder.  Its primary use case is for assets
which are represented as linked data (RDF) where the predicate options may be
too numerous to display nicely on a typical HTML form.

### Basic API

The core class is given a concept of "groups", and the FBO treats this as
associated data:

```ruby
Metadata::Ingest::Form.internal_groups = %w|title subject|
test = Metadata::Ingest::Form.new
test.build_title(type: "main", value: "Test title")
test.build_title(type: "alt", value: "Test title, the")
test.subjects_attributes = {
  "0" => {
    "type" => "lcsh",
    "value" => "Food industry and trade",
    "internal" => "http://id.loc.gov/authorities/subjects/sh85050282"
  }
}
```

The associations store the following attributes:

* `group`: Human interface element for grouping similar data - titles,
  subjects, etc
* `type`: More specific data for what this data means within a group -
  main title, alternate title, etc
* `value`: Human-friendly value
* `internal`: Internal representation of the value, if applicable

Generally speaking, the group isn't set manually since it's determined by the
attribute or builder method name.

#### What it means to set `internal_groups`

This tells objects the internal groups.  Each group gets certain dynamic methods for getting and
setting Metadata::Ingest::Association data.  For the "title" group, for instance:

* `titles`: Returns an array of association objects that are part of the
  "title" group
* `build_title`: Creates a new association with the "title" group
* `titles_attributes=`: Takes parameter-like attributes, creates new
  associations with the group set to "title", and replaces existing titles.

#### About unmapped and raw data

The system also includes its own group, `unmapped_association`, for storing
data that doesn't map to a translateable value.  This is a remnant from the old
system and might go away - it was previously used when an RDF statement matched
the subject of the asset, but the predicate wasn't something we handled on the
form.  This allowed us to write RDF manually without losing the "unknown"
elements.

`@raw_statements` served a similar purpose, but was specific to RDF statements
not related to the subject of the asset.  Its future in the system is also not
certain.

### Within the Rails stack

#### Form

In the controller, you'll set up an ingest form object in some way (note
that there are no built-in classes to help load it from existing data):

```ruby
def setup_form
  @ingest_form = Metadata::Ingest::Form.new
end
```

Form HTML might look like this:

```erb
<%# You must set up the URL - for now, there is no magic to determine persisted vs. new object %>
<%= simple_form_for(ingest_form, {:url => ...}) do |f| %>
  <%= f.simple_fields_for :titles do |f| %>
    <%= f.input :type, :collection => [:main, :alt] %>
    <%= f.input :value %>
    <%= f.hidden_field :internal %>
  <% end %>

  <%= f.simple_fields_for :subjects do |f| %>
    <%= f.input :type, :collection => [:lcsh, :something, :else] %>
    <%= f.input :value %>
    <%= f.hidden_field :internal %>
  <% end %>
<% end %>
```

This gives you a form which has two "entities", but can represent five fields
(main title, alternate title, lcsh subjects, etc).  With proper JavaScript, you
can duplicate fields to allow for more than one within each group.

#### Posted data

The form data comes in looking something like this:

```ruby
{
  "metadata_ingest_form"=>{
    "titles_attributes"=>{
      "0"=>{"type"=>"title", "value"=>"test title"},
      "1"=>{"type"=>"alternate", "value"=>"test alternate title"}
    },
    "subjects_attributes"=>{
      "0"=>{"type"=>"lcsh", "value"=>"Food industry and trade", "internal"=>"http://id.loc.gov/authorities/subjects/sh85050282"}
    }
  }
}
```

#### Translation into asset data

If you use the basic translator, it requires some setup - this could be in the
controller or an initializer, pulled from a database or hard-coded, whatever.
But however it's built, it needs to be set up prior to converting the data.

```ruby
# Set up the map that tells us how forms turn into attributes
form_map = {
  group: {
    type: :attribute_to_delegate,
    type2: :another_attribute,
    deep_delegation: "some_object.attribute"
  },
  title: {
    main: :main_title,
    alt: :alt_title
  },
  subject: {
    lcsh: :lcsh_subject,
    something: :something_subject,
    else: :else_subject
  }
}

# Store the map on the built-in translator
Metadata::Ingest::Translators::FormToAttributes.map = form_map

# Internal groups can be built from the map as well
Metadata::Ingest::Form.internal_groups = form_map.keys.collect {|key| key.to_s}
```

This tells the translator that any associated title data with a type of "main"
will be delegated to the `main_title` field on the asset.  So basically, with
this map in place, the above command:

```ruby
test.build_title(type: "main", value: "Test title")
```

is similar to this:

```ruby
asset.main_title = "Test title"
```

(Note that I say "similar" to - the `FormToAttributes` translation by default
allows any number of any attribute, so a call to `build_title` just adds a new
association, it doesn't remove old data.  For that kind of operation,
`titles_attributes=` is a better, if more verbose, option)

If you need delegation through one or more objects. just specify this in the
map much as you would in code.  Using the `deep_delegation` map, this:

```ruby
test.build_group(type: "deep_delegation", value: "testing")
```

is similar to this:

```ruby
asset.some_object.attribute = "testing"
```

#### Translator in the controller

To make all this magic this work in your controller, you'll have something like
this:

```ruby
def create
  # I can't recall why, but to_hash must be called here.  I might fix it when I have time.
  @form = Metadata::Ingest::Form.new(params[:metadata_ingest_form].to_hash)
  @asset = YourClass.new
  Metadata::Ingest::Translators::FormToAttributes.from(@form).to(@asset)
  @asset.save

  redirect_to :index
end
```

#### Translating from an object to a form

The reverse of the above process is necessary for editing or updating an
existing object.  As is the case above, a basic translator is provided,
`Metadata::Ingest::Translators::AttributesToForm`, and should work for many
cases that just need an object's attributes converted into raw form data.

The map used is the same format at for the form-to-attribute converter,
allowing easier reuse of configuration.  In a controller, you might have
something like this:

```ruby
@asset = YourClass.load_from_some_datasource(params[...])
@form = Metadata::Ingest::Form.new
Metadata::Ingest::Translators::AttributesToForm.from(@asset).to(@form)
```

This is enough for an edit action, but update would require storing new
attributes, translating back to the asset, and saving the asset.

```ruby
# Assign web-form attributes to the ingest form instance which is now loaded
# with asset data
@form.attributes = params[:metadata_ingest_form].to_hash

# Translate form data back into the asset again
Metadata::Ingest::Translators::FormToAttributes.from(@form).to(@asset)

# Save the asset
@asset.save
```

#### Complex translations

The translation from asset to ingest form can be more complicated than the
reverse due to a web form potentially needing to have human-friendly data for
display, but internal data for the system.  For instance, if using Library of
Congress Subject Headings, you might prefer to store a URI to the data, but
display the text.  Your UI should set the `internal` field to said URI when a
user chooses a subject heading.  If you do this, the built-in translator works
as-is for this flow: web form -> ingest form instance -> asset data.  But to go
from attributes back to a form requires some way to detect when an attribute
has an internal value, and then to convert that value.  As this can vary wildly
from situation to situation, we tried to provide an easy-to-customize system
based on subclassing.

Let's assume the above case where subjects are LCSH URIs and need to load into
a form properly.  The following steps would need to be taken:

* Subclass `Metadata::Ingest::Translators::SingleAttributeTranslator`
* In the subclass, override `build_association(value)`
* Use the passed-in value and instance variables to determine how to modify the
  `Metadata::Ingest::Association` instance.  The variables are relevant to the
  context of the current attribute definition, so you can determine which
  group/type/attribute definition you're working with:
  * `@group`: The group as defined in the translation map, e.g., "subject"
  * `@type`: The type as defined in the translation map, e.g., "lcsh"
  * `@attribute_definition`: The attribute defintion as defined in the
    translation map, e.g., "descMetadata.lcsh_subject"
  * `@object`: The actual object which will be used in the case of deep
    delegation.
  * `@attribute`: The attribute which will be looked up on `@object`, again for
    supporting deep delegation.
* Update your translation call to something like this:

```ruby
Metadata::Ingest::Translators::AttributesToForm.
  from(@asset).
  using_translator(YourSuperAwesomeSubclass).
  to(@form)
```

(Note the addition of `using_translator` to the chain)

`@object` and `@attribute` can be used in cases where the final object may be a
delegated object which differs from the source object, as might be the case
when an attribute definition is set to something like
"descMetadata.lcsh_subject".  In that case, `@object` would be the value of
`asset.descMetadata`, and `@attribute` would be "`lcsh_subject`".
`build_association`'s passed-in `value` object would be the result of
`asset.descMetadata.lcsh_subject`.

*tl;dr*: This setup allows us to have a single object which houses all necessary state for a
single attribute's conversion.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
