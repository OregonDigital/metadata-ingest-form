require "metadata/ingest/translators/form_to_attributes"
require_relative "../../../support/map.rb"

describe Metadata::Ingest::Translators::FormToAttributes do
  before(:each) do
    # Set up a translator map
    setup_map(Metadata::Ingest::Translators::FormToAttributes)

    # Make a nice object double with stubs so we know we're expecting exactly what we should
    @object = double("object")
    @object.stub(:title=)
    @object.stub(:alt_title=)
    @object.stub(:photographer=)
    @object.stub(:subject=)
    @object.stub(:some => double("delegatee 1"))
    @object.some.stub(:object => double("delegatee 2"))
    @object.some.object.stub(:deep_title=)
  end

  let(:form_attrs) do
    {
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
  end

  let(:form) { Metadata::Ingest::Form.new(form_attrs) }

  it "delegates a form's data to object attributes" do
    expect(@object).to receive(:title=).with("This is a main title")
    expect(@object).to receive(:alt_title=).with(["alt 1", "alt 2"])
    expect(@object).to receive(:photographer=).with("Photographer Name")
    expect(@object).to receive(:subject=).with("subject keyword")
    Metadata::Ingest::Translators::FormToAttributes.from(form).to(@object)
  end

  it "delegates deep values" do
    expect(@object.some.object).to receive(:deep_title=).with("deep title test")
    Metadata::Ingest::Translators::FormToAttributes.from(form).to(@object)
  end

  it "sets the object to use an internal value when present" do
    int = "http://foo.example.com/ns/102321"
    form_attrs["subjects_attributes"]["14325432"]["internal"] = int
    expect(@object).to receive(:subject=).with(int)
    Metadata::Ingest::Translators::FormToAttributes.from(form).to(@object)
  end

  it "doesn't use a blank internal over a non-blank value" do
    form_attrs["subjects_attributes"]["14325432"]["internal"] = ""
    expect(@object).to receive(:subject=).with("subject keyword")
    Metadata::Ingest::Translators::FormToAttributes.from(form).to(@object)
  end
end
