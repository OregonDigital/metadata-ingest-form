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

    # Set up a pre-populated form
    @filled_form = Metadata::Ingest::Form.new(
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
    )
  end

  it "delegates a form's data to object attributes" do
    object = double("object")
    expect(object).to receive(:title=).with("This is a main title")
    expect(object).to receive(:alt_title=).with(["alt 1", "alt 2"])
    expect(object).to receive(:photographer=).with("Photographer Name")
    expect(object).to receive(:subject=).with("subject keyword")
    p @filled_form.associations
    Metadata::Ingest::Translators::FormToAttributes.from(@filled_form).to(object)
  end
end
