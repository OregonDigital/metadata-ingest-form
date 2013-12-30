require "metadata/ingest/translators/form_to_attributes"

describe Metadata::Ingest::Translators::FormToAttributes do
  before(:each) do
    # This has WAY too much setup - figure out something better!

    # Set up a translator map
    Metadata::Ingest::Translators::FormToAttributes.map = {
      title: {
        main: :title,
        alt: :alt_title,
      },

      creator: {
        creator: :creator,
        photographer: :photographer,
      },

      subject: {
        keyword: :subject,
        lcsh: :lcsh_subject,
      }
    }

    # Use the translator to set up form groups
    Metadata::Ingest::Form.internal_groups = Metadata::Ingest::Translators::FormToAttributes.form_groups
  end

  let(:form_attrs) do
    {
      "titles_attributes" => {
        "1" => {"type" => "main", "value" => "This is a main title"},
        "2" => {"type" => "alt", "value" => "alt 1"},
        "3" => {"type" => "alt", "value" => "alt 2"},
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
    object = double("object")
    expect(object).to receive(:title=).with("This is a main title")
    expect(object).to receive(:alt_title=).with(["alt 1", "alt 2"])
    expect(object).to receive(:photographer=).with("Photographer Name")
    expect(object).to receive(:subject=).with("subject keyword")
    Metadata::Ingest::Translators::FormToAttributes.from(form).to(object)
  end

  it "sets the object to use an internal value when present" do
    int = "http://foo.example.com/ns/102321"
    form_attrs["subjects_attributes"]["14325432"]["internal"] = int
    object = double("object").as_null_object
    expect(object).to receive(:subject=).with(int)
    Metadata::Ingest::Translators::FormToAttributes.from(form).to(object)
  end
end
