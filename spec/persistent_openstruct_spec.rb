require 'lib/persistent_openstruct'

PersistentOpenStruct.config_file = 'spec/storage_config.yml'
class FileBackedOstruct < PersistentOpenStruct; end

shared_examples_for "PersistentOpenStruct" do
  after(:each) { @class.storage.clear }

  it "should act like openstruct" do
    object = @class.new
    object.property = "value"
    object.property.should == "value"
  end
  
  it "should have a key" do
    object = @class.new
    object.key.should_not be_nil
  end
  
  it "should persist and be identical" do
    object = @class.new
    object.sillyness = "quite required"
    
    object2 = @class.find object.key
    object2.sillyness.should == object.sillyness
    
    object2.should == object
    object2.object_id.should == object.object_id
  end
  
  it "should config as an ostruct" do
    FileBackedOstruct.config.class.should == OpenStruct    
  end
end

describe FileBackedOstruct do
  before(:each) { @class = FileBackedOstruct }
  it_should_behave_like "PersistentOpenStruct"
  
  it "should have a storage" do
    FileBackedOstruct.storage.class.should == Moneta::File
  end

  it "should load what it needs to" do
    defined?(Moneta::File).should_not be_nil
  end
end

class RufusBackedOstruct < PersistentOpenStruct; end

describe RufusBackedOstruct do
  before(:each) { @class = RufusBackedOstruct}
  
  it_should_behave_like "PersistentOpenStruct"
  
  it "should have a storage" do
    RufusBackedOstruct.storage.class.should == Moneta::Rufus
  end

  it "should load what it needs to" do
    defined?(Moneta::Rufus).should_not be_nil
  end
end
