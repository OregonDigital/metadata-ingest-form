RSpec::Matchers.define :include_association do |group, type, value|
  match do |associations|
    associations.include?(Metadata::Ingest::Association.new(group: group, type: type, value: value, internal: nil))
  end
end
