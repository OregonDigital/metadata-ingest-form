class SingleTranslatorOverride < Metadata::Ingest::Translators::SingleAttributeTranslator
  def build_association(value)
    assoc = super

    if @object.needs_translation
      assoc.value = "Human-friendly value for #{@group}-#{@type}-#{@attribute}"
      assoc.internal = value
    end

    return assoc
  end
end
