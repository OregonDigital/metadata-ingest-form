require 'ostruct'
require "metadata/ingest/translators/attributes_to_form"
require_relative "../../../support/map.rb"
require_relative "../../../support/single_translator_override.rb"
require_relative "../../../support/include_association.rb"

describe Metadata::Ingest::Translators::AttributesToForm do
  let(:object) do
    OpenStruct.new(
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
  end

  let(:form) {
    f = Metadata::Ingest::Form.new
    f.internal_groups = translation_map.keys.collect(&:to_s)
    f
  }

  let(:translator) {
    Metadata::Ingest::Translators::AttributesToForm.from(object).using_map(translation_map)
  }

  it "builds titles" do
    translator.to(form)
    expect(form.titles).to include_association("title", "main", "This is a main title")
    expect(form.titles).to include_association("title", "alt", "alt 1")
    expect(form.titles).to include_association("title", "alt", "alt 2")
    expect(form.titles).to include_association("title", "deep", "Deep title test")
    expect(form.titles.length).to eq(4)
  end

  it "builds creators" do
    translator.to(form)
    expect(form.creators).to include_association("creator", "photographer", "Photographer Name")
    expect(form.creators).to include_association("creator", "creator", "Creator Name")
    expect(form.creators.length).to eq(2)
  end

  it "builds subjects" do
    translator.to(form)
    expect(form.subjects).to include_association("subject", "keyword", "subject keyword")
    expect(form.subjects).to include_association("subject", "lcsh", "http://foo.example.com/ns/102321")
    expect(form.subjects.length).to eq(2)
  end

  it "doesn't build data when the attribute is nil" do
    object.stub(:title => nil)
    object.stub(:alt_title => nil)
    translator.to(form)
    expect(form.titles).to include_association("title", "deep", "Deep title test")
    expect(form.titles.length).to eq(1)
  end

  it "allows for intercepting data to detect and convert internal values" do
    object.stub(:title => nil)
    object.stub(:alt_title => nil)
    object.some.object.needs_translation = true
    translator.using_translator(SingleTranslatorOverride).to(form)
    assoc = form.titles.first

    expect(assoc.group).to eq("title")
    expect(assoc.type).to eq("deep")
    expect(assoc.value).to eq("Human-friendly value for title-deep-deep_title")
    expect(assoc.internal).to eq("Deep title test")
    expect(form.titles.length).to eq(1)
  end
end
