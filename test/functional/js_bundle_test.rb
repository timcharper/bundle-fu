require File.join(File.dirname(__FILE__), '../test_helper.rb')

class JSBundleTest < Test::Unit::TestCase
  def setup
    @bundle_fu = BundleFu.new({})
  end
  
  def test__bundle_js_files__bypass_bundle__should_bypass
    @bundle_fu.bundle_js_files([])
  end
  
  def test__bundle_js_files__should_include_contents
    bundled_js = @bundle_fu.bundle_js_files(["/javascripts/js_1.js"])
    assert_match("function js_1", bundled_js)
  end
end
