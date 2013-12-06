require "metadata/ingest/association"

describe Metadata::Ingest::Association do
  before(:each) do
    @association = Metadata::Ingest::Association.new
  end

  describe ".new" do
    it "should set @type if a :type is passed in" do
      Metadata::Ingest::Association.new(:type => :main).type.should eq(:main)
    end

    it "should work without any arguments" do
      Metadata::Ingest::Association.new
    end

    it "should set @value if a :value is passed in" do
      Metadata::Ingest::Association.new(:value => "value").value.should eq("value")
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
      @association.should_not be_valid
      @association.errors[:value].should_not eq([])
      @association.errors[:type].should eq([])
    end

    it "should be invalid if @value is set but type isn't" do
      @association.type = ""
      @association.should_not be_valid
      @association.errors[:type].should_not eq([])
      @association.errors[:value].should eq([])
    end

    it "should be valid if both @type and @value are set" do
      @association.should be_valid
      @association.errors[:value].should eq([])
      @association.errors[:type].should eq([])
      @association.errors.should be_empty
    end

    it "should be valid if the object is blank" do
      @association.stub(:blank?).and_return true
      @association.should be_valid
      @association.errors[:value].should eq([])
      @association.errors[:type].should eq([])
      @association.errors.should be_empty
    end
  end

  describe "#blank?" do
    before(:each) do
      @association.type = ""
      @association.value = ""
    end

    it "should return true if @type and @value are blank" do
      @association.blank?.should eq(true)
    end

    it "should return false if @type isn't blank" do
      @association.type = "something"
      @association.blank?.should eq(false)
    end

    it "should return false if @value isn't blank" do
      @association.value = "something"
      @association.blank?.should eq(false)
    end
  end
end
