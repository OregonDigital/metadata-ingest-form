require "metadata/ingest/translators/form_to_attributes"
require_relative "../../../support/map.rb"

describe Metadata::Ingest::Translators::FormToAttributes do
  before(:each) do
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

  let(:form) {
    f = Metadata::Ingest::Form.new(form_attrs)
    f.internal_groups = translation_map.keys.collect(&:to_s)
    f
  }

  let(:translator) do
    Metadata::Ingest::Translators::FormToAttributes.from(form).using_map(translation_map)
  end

  it "delegates a form's data to object attributes" do
    expect(@object).to receive(:title=).with("This is a main title")
    expect(@object).to receive(:alt_title=).with(["alt 1", "alt 2"])
    expect(@object).to receive(:photographer=).with("Photographer Name")
    expect(@object).to receive(:subject=).with("subject keyword")
    translator.to(@object)
  end

  it "delegates deep values" do
    expect(@object.some.object).to receive(:deep_title=).with("deep title test")
    translator.to(@object)
  end

  it "sets the object to use an internal value when present" do
    int = "http://foo.example.com/ns/102321"
    form_attrs["subjects_attributes"]["14325432"]["internal"] = int
    expect(@object).to receive(:subject=).with(int)
    translator.to(@object)
  end

  it "doesn't use a blank internal over a non-blank value" do
    form_attrs["subjects_attributes"]["14325432"]["internal"] = ""
    expect(@object).to receive(:subject=).with("subject keyword")
    translator.to(@object)
  end

  context "(when an alternate title is destroyed)" do
    before(:each) do
      # Mark the first alt title for destruction
      form_attrs["titles_attributes"]["2"]["_destroy"] = "1"
    end

    it "should set non-destroyed data, effectively ignored the destroyed item" do
      expect(@object).to receive(:alt_title=).with("alt 2")
      translator.to(@object)
    end

    it "should call `obj.alt_title = nil` if both items are destroyed" do
      form_attrs["titles_attributes"]["3"]["_destroy"] = "1"
      expect(@object).to receive(:alt_title=).with(nil)
      translator.to(@object)
    end
  end
end
