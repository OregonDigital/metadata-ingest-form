# Sets up a map for the given translator
def setup_map(translator)
  translator.map = translation_map
end

# Returns the translation map used for tests
def translation_map
  return {
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
end
