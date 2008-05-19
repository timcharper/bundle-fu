require File.join(File.dirname(__FILE__), '../../spec_helper.rb')

describe BundleFu::CSSUrlRewriter do
  before(:each) do
    @bundle_fu = BundleFu.new({})
  end
  
  it "should rewrite_relative_path__should_rewrite" do
    assert_rewrites("/stylesheets/active_scaffold/default/stylesheet.css", 
      "../../../images/spinner.gif" => "/images/spinner.gif",
      "../../../images/./../images/goober/../spinner.gif" => "/images/spinner.gif"
    )
    
    assert_rewrites("stylesheets/active_scaffold/default/./stylesheet.css", 
      "../../../images/spinner.gif" => "/images/spinner.gif")
      
    assert_rewrites("stylesheets/main.css", 
      "image.gif" => "/stylesheets/image.gif")
      
    assert_rewrites("/stylesheets////default/main.css", 
      "..//image.gif" => "/stylesheets/image.gif")
      
    assert_rewrites("/stylesheets/default/main.css", 
      "/images/image.gif" => "/images/image.gif")
  end
  
  it "should rewrite_relative_path__should_strip_spaces_and_quotes" do
    assert_rewrites("stylesheets/main.css", 
      "'image.gif'" => "/stylesheets/image.gif",
      " image.gif " => "/stylesheets/image.gif"
    )
  end
  
  it "should rewrite_relative_path__shouldnt_rewrite_if_absolute_url" do
    assert_rewrites("stylesheets/main.css", 
      " 'http://www.url.com/images/image.gif' " => "http://www.url.com/images/image.gif",
      "http://www.url.com/images/image.gif" => "http://www.url.com/images/image.gif",
      "ftp://www.url.com/images/image.gif" => "ftp://www.url.com/images/image.gif"
    )
  end
  
  it "should bundle_css_file__should_rewrite_relatiave_path" do
    bundled_css = @bundle_fu.bundle_css_files(["/stylesheets/css_3.css"])
    bundled_css.should include("background-image: url(/images/background.gif)")
    bundled_css.should include("background-image: url(/images/groovy/background_2.gif)")
  end
  
  it "should bundle_css_files__no_images__should_return_content" do
    bundled_css = @bundle_fu.bundle_css_files(["/stylesheets/css_1.css"])
    bundled_css.should include("css_1 { }")
  end
  
  
  def assert_rewrites(source_filename, rewrite_map)
    rewrite_map.each_pair do |source, dest|
      BundleFu::CSSUrlRewriter.rewrite_relative_path(source_filename, source).should == dest
    end
  end
end
