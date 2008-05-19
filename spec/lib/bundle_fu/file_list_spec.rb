require File.join(File.dirname(__FILE__), '../../spec_helper.rb')

describe BundleFu::FileList do
  it "should new_files__should_get_mtimes" do
    filename = "/javascripts/js_1.js"
    filelist = BundleFu::FileList.new([filename])
    
    filelist.filelist[0][1].should == File.mtime(File.join(RAILS_ROOT, "public", filename)).to_i
  end
  
  it "should serialization" do
    begin
      filelist_filename = File.join(RAILS_ROOT, "public", "temp")
      filelist = BundleFu::FileList.new("/javascripts/js_1.js")
    
      filelist.save_as(filelist_filename)
      filelist2 = BundleFu::FileList.open(filelist_filename)
    
      filelist.should == filelist2
    ensure
      FileUtils.rm_f(filelist_filename)
    end
  end
  
  it "should equality__same_file_and_mtime__should_equate" do
    filename = "/javascripts/js_1.js"
    BundleFu::FileList.new(filename).should == BundleFu::FileList.new(filename)
  end
  
  it "should equality__dif_file_and_mtime__shouldnt_equate" do
    filename1 = "/javascripts/js_1.js"
    filename2 = "/javascripts/js_2.js"
    BundleFu::FileList.new(filename1).should_not == BundleFu::FileList.new(filename2)
  end
  
  it "should clone_item" do
    b = BundleFu::FileList.new("/javascripts/js_1.js")
    b.should == b.clone
  end
end