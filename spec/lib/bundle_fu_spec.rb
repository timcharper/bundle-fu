require File.join(File.dirname(__FILE__), '../spec_helper.rb')

describe "BundleFu" do
  before(:each) do
    @mock_view = MockView.new
    BundleFu.reset!
  end
  
  after(:each) do
    purge_cache
  end
  
  it "should bundle_js_files__should_include_js_content" do
    @mock_view.bundle { CONTENT_INCLUDE_ALL }
    public_file_contents("/javascripts/cache/bundle.js").should include("function js_1()")
  end
  
  it "should bundle_js_files_with_asset_server_url" do
    @mock_view.bundle { %(<script src="https://assets.server.com/javascripts/js_1.js?1000" type="text/javascript"></script>) }
    public_file_contents("/javascripts/cache/bundle.js").should include("function js_1()")
  end
  
  it "should bundle_js_files__should_use_packr" do
    Object.send :class_eval, <<EOF
    class ::Object::Packr
      def initialize
      end
      
      def pack(content, options={})
        "PACKR!" + options.inspect
      end
      
    end
EOF
    
    @mock_view.bundle() { CONTENT_INCLUDE_ALL }
    public_file_contents("/javascripts/cache/bundle.js").should include("PACKR")
    purge_cache
    
    @mock_view.bundle(:packr_options => {:packr_options_here => "hi_packr"}) { CONTENT_INCLUDE_ALL }
    public_file_contents("/javascripts/cache/bundle.js").should include("packr_options_here")
    
    Object.send :remove_const, "Packr"
  end
  
  it "should bundle_js_files__should_default_to_not_compressed_and_include_override_option" do
    @mock_view.bundle() { CONTENT_INCLUDE_ALL }
    default_content = public_file_contents(("/javascripts/cache/bundle.js"))
    purge_cache
    
    @mock_view.bundle(:compress => false) { CONTENT_INCLUDE_ALL }
    uncompressed_content = public_file_contents("/javascripts/cache/bundle.js")
    purge_cache
    
    @mock_view.bundle(:compress => true) { CONTENT_INCLUDE_ALL }
    compressed_content = public_file_contents("/javascripts/cache/bundle.js")
    purge_cache
    
    default_content.length.should == compressed_content.length
    uncompressed_content.length.should > compressed_content.length
  end
  
  it "should content_remains_same__shouldnt_refresh_cache" do
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    
    # check to see each bundle file exists and append some text to the bottom of each file
    append_to_public_files(cache_files("bundle"), "BOGUS")
    public_file_contents("/javascripts/cache/bundle.js").should include("BOGUS")
    public_file_contents("/stylesheets/cache/bundle.css").should include("BOGUS")
    
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    
    public_file_contents("/javascripts/cache/bundle.js").should include("BOGUS")
    public_file_contents("/stylesheets/cache/bundle.css").should include("BOGUS")
  end
  
  it "should content_changes__should_refresh_cache" do
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    
    # check to see each bundle file exists and append some text to the bottom of each file
    append_to_public_files(cache_files("bundle"), "BOGUS")
    cache_files("bundle").each { |cf| public_file_contents(cf).should include("BOGUS") }
    
    
    # now, pass in some new content.  Make sure that the css/js files are regenerated
    @mock_view.bundle { CONTENT_INCLUDE_ALL }
    cache_files("bundle").each { |cf| public_file_contents(cf).should_not include("BOGUS") }
  end
  
  it "should modified_time_differs_from_file__should_refresh_cache" do
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    # we're gonna hack each of them and set all the modified times to 0
    cache_files("bundle").each do |filename|
      abs_filelist_path = public_filepath(filename + ".filelist")
      b = BundleFu::FileList.open(abs_filelist_path)
      b.filelist.each{|entry| entry[1] = entry[1] - 100 }
      b.save_as(abs_filelist_path)
    end
    
    append_to_public_files(cache_files("bundle"), "BOGUS")
  end
  
  it "should content_remains_same_but_cache_files_dont_match_whats_in_content__shouldnt_refresh_cache" do
    # it shouldnt parse the content unless if it differed from the last request.  This scenario should never exist, and if it did it would be fixed when the server reboots.
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    abs_filelist_path = public_filepath("/stylesheets/cache/bundle.css.filelist")
    b = BundleFu::FileList.open(abs_filelist_path)
    
    @mock_view.bundle { CONTENT_INCLUDE_ALL }
    b.save_as(abs_filelist_path)
    append_to_public_files(cache_files("bundle"), "BOGUS")
    
    @mock_view.bundle { CONTENT_INCLUDE_ALL }
    public_files_contents(cache_files("bundle")).each_should include("BOGUS")
  end
  
  it "should content_differs_slightly_but_cache_files_match__shouldnt_refresh_cache" do
    @mock_view.bundle { CONTENT_INCLUDE_ALL }
    append_to_public_files(cache_files("bundle"), "BOGUS")
    @mock_view.bundle { CONTENT_INCLUDE_ALL + "  " }
    public_files_contents(cache_files("bundle")).each_should include("BOGUS")
  end
  
  it "should bundle__js_only__should_output_js_include_statement" do
    @mock_view.bundle { CONTENT_INCLUDE_SOME.split("\n").first }
    lines = @mock_view.output.split("\n")
    lines.length.should == 1
    lines.first.should match(/javascripts/)
  end
  
  it "should bundle__css_only__should_output_css_include_statement" do
    @mock_view.bundle { CONTENT_INCLUDE_SOME.split("\n")[2] }
    lines = @mock_view.output.split("\n")
    
    lines.length.should == 1
    lines.first.should match(/stylesheets/)
  end
  
  it "should nonexisting_file__should_use_blank_file_created_at_0_mtime" do
    @mock_view.bundle { %q{<script src="/javascripts/non_existing_file.js?1000" type="text/javascript"></script>} } 
    
    public_files_contents(cache_files("bundle").grep(/javascripts/)).each_should include("FILE READ ERROR")
    
    filelist = BundleFu::FileList.open(public_filepath("/javascripts/cache/bundle.js.filelist"))
    filelist.filelist[0][1].should == 0
  end
  
  it "should missing_cache_filelist__should_regenerate" do
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    append_to_public_files(cache_files("bundle"), "BOGUS")
    
    # now delete the cache files
    Dir[ public_filepath("**/*.filelist")].each{|filename| FileUtils.rm_f filename }
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    cache_files("bundle").should_not include("BOGUS")
  end
  
  it "should bypass__should_not_generate_files_but_render_normal_output" do
    @mock_view.bundle(:bypass => true) { CONTENT_INCLUDE_SOME }
    File.exist?(public_filepath("/stylesheets/cache/bundle.css")).should == false
    File.exist?(public_filepath("/stylesheets/cache/bundle.css.filelist")).should == false
    
    @mock_view.output.should == CONTENT_INCLUDE_SOME
  end
  
  it "should bypass_param_set__should_honor_and_store_in_session" do
    @mock_view.params[:bundle_fu] = "false"
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    @mock_view.output.should == CONTENT_INCLUDE_SOME
    
    @mock_view.params.delete(:bundle_fu)
    @mock_view.bundle { CONTENT_INCLUDE_SOME }
    @mock_view.output.should == CONTENT_INCLUDE_SOME*2
  end
  
private
  
  def purge_cache
    # remove all fixtures named "bundle*"
    Dir[ public_filepath("**/cache") ].each{|filename| FileUtils.rm_rf filename }
  end
  
  def assert_public_file_exists(filename, message=nil)
    assert_file_exists(public_filepath(filename), message)
  end
  
  def assert_public_file_not_exists(filename, message=nil)
    assert_file_not_exists(public_filepath(filename), message)
  end
  
  def assert_file_exists(filename, message=nil)
    File.exists?(filename).should == true
  end
  
  def assert_file_not_exists(filename, message=nil)
    !File.exists?(filename).should == true
  end
  
  def cache_files(name)
    ["/javascripts/cache/#{name}.js", "/stylesheets/cache/#{name}.css"]
  end

  def append_to_public_files(filenames, content)
    for filename in filenames
      assert_public_file_exists(filename)
      File.open(public_filepath(filename), "a") {|f|
        f.puts(content)
      }
    end
  end  
end


describe "JSBundle" do
  before(:each) do
    @bundle_fu = BundleFu.new({})
  end
  
  it "should bundle_js_files__bypass_bundle__should_bypass" do
    @bundle_fu.bundle_js_files([])
  end
  
  it "should bundle_js_files__should_include_contents" do
    bundled_js = @bundle_fu.bundle_js_files(["/javascripts/js_1.js"])
    bundled_js.should include("function js_1")
  end
end
