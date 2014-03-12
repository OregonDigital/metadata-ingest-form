require "metadata/ingest/form"
require "ostruct"
require_relative "../../support/include_association.rb"

describe Metadata::Ingest::Form do
  before(:each) do
    @if = Metadata::Ingest::Form.new
    @if.internal_groups = ["title", "subject"]
  end

  describe ".reflect_on_association" do
    it "should return nil" do
      expect(Metadata::Ingest::Form.reflect_on_association(nil)).to be_nil
      expect(Metadata::Ingest::Form.reflect_on_association(:titles)).to be_nil
    end
  end

  describe ".new" do
    context "(when no attributes are passed in)" do
      it "should set up an empty array of titles" do
        form = Metadata::Ingest::Form.new
        form.internal_groups = ["title", "subject"]
        expect(form.titles).to eq([])

        form = Metadata::Ingest::Form.new(:foo => 1, :bar => 2)
        form.internal_groups = ["title", "subject"]
        expect(form.titles).to eq([])
      end
    end

    context "(when nil is passed in)" do
      before(:each) do
        @if = Metadata::Ingest::Form.new(nil)
        @if.internal_groups = ["title", "subject"]
      end

      it "shouldn't call #attributes= at all" do
        expect_any_instance_of(Metadata::Ingest::Form).not_to receive(:attributes=)
        Metadata::Ingest::Form.new(nil)
      end

      it "should set @data to an empty hash" do
        expect(@if.instance_variable_get("@data")).to eq({})
      end

      it "should still set up an empty array of titles" do
        expect(@if.titles).to eq([])
      end
    end

    context "(when attributes are passed in)" do
      it "should set attributes via #attributes=" do
        attributes = double("titles attributes")
        expect_any_instance_of(Metadata::Ingest::Form).to receive(:attributes=).with(attributes).once
        Metadata::Ingest::Form.new(attributes)
      end
    end
  end

  describe "#associations" do
    before(:each) do
      @groups = ["a", "b"]
      @if.stub(:groups).and_return(@groups)

      @associations = []
      for group in @groups
        items = [
          OpenStruct.new(:group => group, :value => 1),
          OpenStruct.new(:group => group, :value => 2),
        ]
        @if.add_association(items[0])
        @if.add_association(items[1])
        @associations.push(*items)
      end

      # Paranoid sanity verification - since we use this attribute to prove things work, let's make
      # sure we populated it correctly
      expect(@associations.collect {|assoc| assoc.group + assoc.value.to_s}).to eq(["a1", "a2", "b1", "b2"])
    end

    it "should return all associations" do
      expect(@if.associations).to eq(@associations)
    end

    it "shouldn't be mutable" do
      expect { @if.associations << double.as_null_object }.to raise_error
      expect(@if.associations).to be_frozen
    end
  end

  describe "#attributes=" do
    let(:attributes) do
      {
        "titles_attributes" => {
          "1" => {"type" => "main", "value" => "Main title"},
          "2" => {"type" => "main", "value" => "Main title #2"}
        },
        "foos_attributes" => {
          "1" => {"type" => "lcsh", "value" => "Blah"},
        }
      }
    end

    before(:each) do
      @if.attributes = attributes
    end

    it "should create one association for each valid group" do
      expect(@if.associations.length).to eq(2)
    end

    it "should expose data for all valid groups" do
      expect(@if.titles).to include_association("title", "main", "Main title")
      expect(@if.titles).to include_association("title", "main", "Main title #2")
    end

    it "should prevent accessing invalid groups' data" do
      expect(@if.associations).to match_array(@if.titles)
      expect(@if.associations).not_to include_association("foo", "lcsh", "Blah")
    end

    it "should expose extra data if the groups are changed to make 'bad' data valid" do
      @if.internal_groups << "foo"
      expect(@if.associations.length).to eq(3)
      expect(@if.associations).to include_association("foo", "lcsh", "Blah")
    end

    context "(when '_destroy' is present)" do
      it "should flag items for deletion that have the _destroy flag set to '1'" do
        attributes["titles_attributes"]["1"]["_destroy"] = "1"
        @if.attributes = attributes
        t1 = @if.associations[0]
        t2 = @if.associations[1]
        expect(t1.value).to eq("Main title")
        expect(t2.value).to eq("Main title #2")
        expect(t1.marked_for_destruction?).to be_true
        expect(t2.marked_for_destruction?).to be_false
      end

      it "should act as it always does if _destroy is set to 'false'" do
        attributes["titles_attributes"]["1"]["_destroy"] = "false"
        @if.attributes = attributes
        expect(@if.associations.length).to eq(2)
        expect(@if.titles).to include_association("title", "main", "Main title")
        expect(@if.titles).to include_association("title", "main", "Main title #2")
      end
    end
  end

  describe "dynamic method system" do
    before(:each) do
      @groups = ["foo", "bar"]
      @if.stub(:groups).and_return(@groups)

      @bulk_assign = "%ss_attributes="
      @builder = "build_%s"
      @getter = "%ss"
    end

    it "should respond to the dynamic methods" do
      for group in @groups
        expect(@if).to respond_to(@bulk_assign % group)
        expect(@if).to respond_to(@builder % group)
        expect(@if).to respond_to(@getter % group)
      end
    end

    it "should not respond to plural builder (i.e., @if.build_foos is wrong.  @if.build_foo is right)" do
      expect(@if).not_to respond_to(:build_foos)
    end

    it "should not respond to singular attributes= (i.e., @if.foo_attributes= is wrong.  @if.foos_attributes= is right)" do
      expect(@if).not_to respond_to(:foo_attributes=)
    end

    it "should not respond to singular getter (i.e., @if.foo is wrong.  @if.foos is right)" do
      expect(@if).not_to respond_to(:foo)
    end

    it "should not respond to dynamic methods for invalid groups" do
      @if.stub(:groups).and_return([])
      for group in @groups
        expect(@if).not_to respond_to(@bulk_assign % group)
        expect(@if).not_to respond_to(@builder % group)
        expect(@if).not_to respond_to(@getter % group)
      end
    end

    it "should expose methods which create and access data properly" do
      @if.foos_attributes = {
        0 => {:type => "type 0", :value => "value 0", :internal => 0},
        1 => {:type => "type 1", :value => "value 1", :internal => 1},
      }
      @if.build_foo(:type => "type 2", :value => "value 2", :internal => 2)
      for foo in @if.foos
        expect(foo.group).to eq("foo")
        expect(foo.type).to match(/^type \d$/)
        foo.type =~ /(\d)/
        expect(foo.value).to eq("value #{$1}")
        expect(foo.internal).to eq($1.to_i)
      end
    end
  end

  context "(validations)" do
    before(:each) do
      # Set up fake group
      @valid_groups = ["title", "thing"]
      @if.stub(:groups).and_return(@valid_groups)

      # Build some bad data
      @if.build_title(:type => "foo")
      @if.build_title(:value => "bar")
      @if.build_thing(:type => "", :value => "value")
    end

    it "should be invalid if any association objects are invalid" do
      expect(@if).not_to be_valid
    end

    it "should set errors based on association objects' errors" do
      # Have to call this for validation checks to populate the errors object
      @if.valid?

      # Each bad item above should generate specific errors on the ingest form object
      expect(@if.errors[:"title.type"]).not_to be_blank
      expect(@if.errors[:"title.value"]).not_to be_blank
      expect(@if.errors[:"thing.type"]).not_to be_blank
      expect(@if.errors.count).to eq(3)
    end

    it "should be valid if all association objects are valid" do
      @if.titles[0].value = "fixed"
      @if.titles[1].type = "fixed"
      @if.things[0].type = "fixed"
      expect(@if).to be_valid
      expect(@if.errors.count).to eq(0)
    end
  end

  # The rest of the tests are somewhat overkill, but I want them kept for a few reasons:
  # * They prove a real-world case works - titles
  # * They cover the code paths that any dynamic method set will hit
  # * They are very fast to run - i.e., they aren't adding much overhead for what they provide
  #   (about 1/100th of a second added to test execution)
  #
  # If they get unwieldy or painful to maintain, they could probably be scrapped, but then we'll
  # just need to test similar functionality in other ways.

  describe "#titles_attributes=" do
    before(:each) do
      @data1 = {:type => 1, :value => "one"}
      @data2 = {:type => 2, :value => "two"}
      @data3 = {:type => 3, :value => "three"}

      @it1 = double("Metadata::Ingest::Association 1")
      @it2 = double("Metadata::Ingest::Association 2")
      @it3 = double("Metadata::Ingest::Association 3")

      @hash = {:foo => @data1, :bar => @data2, :baz => @data3}

      Metadata::Ingest::Association.stub(:new).with(@data1).and_return(@it1)
      Metadata::Ingest::Association.stub(:new).with(@data2).and_return(@it2)
      Metadata::Ingest::Association.stub(:new).with(@data3).and_return(@it3)
    end

    it "should clear out previous titles" do
      old_title1 = double("old title 1")
      old_title2 = double("old title 2")

      @if.titles << old_title1
      @if.titles << old_title2
      expect(@if.titles).to include(old_title1, old_title2)

      @if.titles_attributes = @hash
      expect(@if.titles).not_to include(old_title1, old_title2)
    end

    it "should create a new Metadata::Ingest::Association with each attribute's data" do
      expect(Metadata::Ingest::Association).to receive(:new).with(@data1).once.and_return(@it1)
      expect(Metadata::Ingest::Association).to receive(:new).with(@data2).once.and_return(@it2)
      expect(Metadata::Ingest::Association).to receive(:new).with(@data3).once.and_return(@it3)

      @if.titles_attributes = @hash
    end

    it "should store the new titles" do
      @if.titles_attributes = @hash
      expect(@if.titles.length).to eq(3)
      expect(@if.titles).to include(@it1, @it2, @it3)
    end

    it "shouldn't use the hash key for anything" do
      # This test verifies that we just blow away titles data instead of trying to use the hash
      # key as an identifier to update data.  In ActiveRecord, where each object is in a table and
      # costs a lot to delete and re-create, this would be bad, but our object is currently just one
      # blob of data for all titles, so there isn't really an atomic way to update a single title.
      # This isn't a necessary test to prove functionality is working, but rather a test to ensure
      # that this behavior doesn't change without a test failing, and hopefully careful
      # consideration prior to making such a change.

      @hash[:fizzy] = @hash.delete(:foo)
      expect(@hash[:foo]).to be_nil

      @if.titles_attributes = @hash
      expect(@if.titles.length).to eq(3)
      expect(@if.titles).to include(@it1, @it2, @it3)
    end
  end

  describe "#build_title" do
    before :each do
      @args = {:value => "Args for a title", :type => :main}
      @title = double("Metadata::Ingest::Association")

      Metadata::Ingest::Association.stub(:new).with(@args).and_return(@title)
    end

    it "should create a new Metadata::Ingest::Association with whatever parameters are passed in" do
      expect(Metadata::Ingest::Association).to receive(:new).with(@args)
      @if.build_title(@args)
    end

    it "should add the Metadata::Ingest::Association to titles" do
      @if.build_title(@args)
      expect(@if.titles).to include(@title)
    end

    it "should return the created title" do
      expect(@if.build_title(@args)).to eq(@title)
    end
  end

  context "(dependency injection)" do
    it "should use a custom association class if set" do
      args = {:value => "Args for a title", :type => :main}
      fake_class = double(:association_class)
      @if.association_class = fake_class

      expect(fake_class).to receive(:new).with(args)
      @if.build_title(args)
    end
  end
end
