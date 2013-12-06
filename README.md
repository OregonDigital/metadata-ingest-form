# Metadata::Ingest::Form

Provides form-backing objects for metadata models

An attempt to provide simpler access to complex back-end data by telling the
form how to group similar fields into a single dual-field entity ("type" and
"value" combine to tell the system what the field actually means).  This only
provides a model for doing this - translation is currently not included.

### READ THIS!

This project is a port from the old prototype code we built.  It will probably
not make sense outside the OregonDigital project for a long time, if ever.

The goal is to extract the old code to separate it from some of the hard-coded
rules which were applied in the prototype and see what components can be put
into libraries vs. having to live back in the application itself.  This might
all get merged into the app, there may be multiple separate gems that each
provide different pieces of the functionality, there may end up being one gem
with all the ingest logic, there may end up being a mountable engine, who
knows....  But for now it's just here to extract code and see how the old stuff
can be used in the new system.

## Installation

Add this line to your application's Gemfile:

    gem 'metadata-ingest-form'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install metadata-ingest-form

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
