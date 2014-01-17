require 'ostruct'
require "metadata/ingest/translators/form_to_attributes"
require "metadata/ingest/translators/attributes_to_form"
require_relative "../support/map.rb"

describe "round-trip translation" do
  before(:each) do
    # Use the map to set up form groups
    Metadata::Ingest::Form.internal_groups = translation_map.keys.collect(&:to_s)
  end

  it "should go from an ingest form to object and back to an ingest form properly" do
    form_attrs = {
      "titles_attributes" => {
        "1" => {"type" => "main", "value" => "This is a main title"},
        "2" => {"type" => "alt", "value" => "alt 1"},
        "3" => {"type" => "alt", "value" => "alt 2"},
        "4" => {"type" => "deep", "value" => "deep title test"},
      },
      "creators_attributes" => {
        "1" => {"type" => "photographer", "value" => "Photographer Name"}
      },
      "subjects_attributes" => {
        "14325432" => {"type" => "keyword", "value" => "subject keyword"}
      }
    }
    form = Metadata::Ingest::Form.new(form_attrs)

    # This is weird but we have to have a place for the deep title data to go
    object = OpenStruct.new(some: OpenStruct.new(object: OpenStruct.new))

    Metadata::Ingest::Translators::FormToAttributes.from(form).using_map(translation_map).to(object)

    # Sanity check
    expect(object.some.object.deep_title).to eql("deep title test")
    expect(object.alt_title).to eql(["alt 1", "alt 2"])

    new_form = Metadata::Ingest::Form.new
    Metadata::Ingest::Translators::AttributesToForm.from(object).using_map(translation_map).to(new_form)

    for assoc in form.associations
      expect(new_form.associations).to include(assoc)
    end
    expect(new_form.associations.length).to eq(form.associations.length)
  end

  it "should go from an object to an ingest form and back to an object properly" do
    object = OpenStruct.new(
      title: "This is a main title",
      alt_title: ["alt 1", "alt 2"],
      some: OpenStruct.new(
        object: OpenStruct.new(
          deep_title: "Deep title test"
        )
      ),
      photographer: "Photographer Name",
      subject: "subject keyword",
      lcsh_subject: "http://foo.example.com/ns/102321",
      creator: "Creator Name",
    )

    form = Metadata::Ingest::Form.new
    Metadata::Ingest::Translators::AttributesToForm.from(object).using_map(translation_map).to(form)

    # Sanity check
    expected_subject = Metadata::Ingest::Association.new(
      group: "subject",
      type: "keyword",
      value: "subject keyword"
    )
    expect(form.subjects).to include(expected_subject)
    expect(form.subjects.length).to eq(2)

    # This is weird but we have to have a place for the deep title data to go
    new_object = OpenStruct.new(some: OpenStruct.new(object: OpenStruct.new))

    Metadata::Ingest::Translators::FormToAttributes.from(form).using_map(translation_map).to(new_object)

    expect(new_object).to eq(object)
  end
end
