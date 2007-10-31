require File.join(File.dirname(__FILE__), '../test_helper.rb')

class CSSBundleTest < Test::Unit::TestCase
  def test__rewrite_relative_path__should_rewrite
    assert_equal("/images/spinner.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("/stylesheets/active_scaffold/default/stylesheet.css", "../../../images/spinner.gif"))
    assert_equal("/images/spinner.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("/stylesheets/active_scaffold/default/stylesheet.css", "../../../images/./../images/goober/../spinner.gif"))
    assert_equal("/images/spinner.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("stylesheets/active_scaffold/default/./stylesheet.css", "../../../images/spinner.gif"))
    assert_equal("/stylesheets/image.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("stylesheets/main.css", "image.gif"))
    assert_equal("/stylesheets/image.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("stylesheets/main.css", "'image.gif'"))
    assert_equal("/stylesheets/image.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("stylesheets/main.css", " image.gif "))
    assert_equal("/stylesheets/image.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("/stylesheets////default/main.css", "..//image.gif"))
    assert_equal("/images/image.gif", BundleFu::CSSUrlRewriter.rewrite_relative_path("/stylesheets/default/main.css", "/images/image.gif"))
  end
  
  def test__bundle_css_file__should_rewrite_relatiave_path
#    dbg
    bundled_css = BundleFu.bundle_css_files(["/stylesheets/css_3.css"])
#    puts bundled_css
    assert_match("background-image: url(/images/background.gif)", bundled_css)
    assert_match("background-image: url(/images/groovy/background_2.gif)", bundled_css)
  end
  
  def test__bundle_css_files__no_images__should_return_content
    bundled_css = BundleFu.bundle_css_files(["/stylesheets/css_1.css"])
    assert_match("css_1 { }", bundled_css)
    
  end
end
