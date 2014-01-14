# Sets up a map for the given translator, and sets the ingest form's internal
# groups based on the map's groups
def setup_map(translator)
  # Set up a translator map
  translator.map = {
    title: {
      main: :title,
      alt: :alt_title,
      deep: "some.object.deep_title",
    },

    creator: {
      creator: :creator,
      photographer: :photographer,
    },

    subject: {
      keyword: :subject,
      lcsh: :lcsh_subject,
    },
  }

  # Use the translator to set up form groups
  Metadata::Ingest::Form.internal_groups = translator.form_groups
end
