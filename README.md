# Metadata::Ingest::Form

Provides form-backing objects for metadata models

An attempt to provide simpler access to complex back-end data by telling the
form how to group similar fields into a multiple field entity.  This only
provides a model for doing this and a simple attribute-delegation translator.
No UI elements are provided, and complex translation is left as an exercise to
the reader.

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
    type: attribute_to_delegate,
    type2: another_attribute
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
