require "metadata/ingest/association"

describe Metadata::Ingest::Association do
  before(:each) do
    @association = Metadata::Ingest::Association.new
  end

  describe ".new" do
    it "should set @type if a :type is passed in" do
      expect(Metadata::Ingest::Association.new(:type => :main).type).to eq(:main)
    end

    it "should work without any arguments" do
      Metadata::Ingest::Association.new
    end

    it "should set @value if a :value is passed in" do
      expect(Metadata::Ingest::Association.new(:value => "value").value).to eq("value")
    end

    it "should set @internal if a :internal is passed in" do
      expect(Metadata::Ingest::Association.new(:internal => "internal").internal).to eq("internal")
    end
  end

  # Validations
  context "(validations)" do
    before(:each) do
      @association.group = "title"
      @association.type = "main"
      @association.value = "Title"
    end

    it "should be invalid if @type is set but @value isn't" do
      @association.value = ""
      expect(@association).not_to be_valid
      expect(@association.errors[:value]).not_to eq([])
      expect(@association.errors[:type]).to eq([])
    end

    it "should be invalid if @value is set but type isn't" do
      @association.type = ""
      expect(@association).not_to be_valid
      expect(@association.errors[:type]).not_to eq([])
      expect(@association.errors[:value]).to eq([])
    end

    it "should be valid if both @type and @value are set" do
      expect(@association).to be_valid
      expect(@association.errors[:value]).to eq([])
      expect(@association.errors[:type]).to eq([])
      expect(@association.errors).to be_empty
    end

    it "should be valid whether or not internal is set" do
      @association.internal = "foo"
      expect(@association).to be_valid
      @association.internal = ""
      expect(@association).to be_valid
      @association.internal = nil
      expect(@association).to be_valid
    end

    it "should be valid if the object is blank" do
      @association.stub(:blank?).and_return true
      expect(@association).to be_valid
      expect(@association.errors[:value]).to eq([])
      expect(@association.errors[:type]).to eq([])
      expect(@association.errors).to be_empty
    end
  end

  describe "#blank?" do
    before(:each) do
      @association.type = ""
      @association.value = ""
    end

    it "should return true if @type and @value are blank" do
      expect(@association).to be_blank
    end

    it "should return false if @type isn't blank" do
      @association.type = "something"
      expect(@association).not_to be_blank
    end

    it "should return false if @value isn't blank" do
      @association.value = "something"
      expect(@association).not_to be_blank
    end
  end
end
