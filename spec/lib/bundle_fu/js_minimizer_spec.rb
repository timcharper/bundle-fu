require File.join(File.dirname(__FILE__), '../../spec_helper.rb')

describe BundleFu::JSMinimizer do
  it "should shrink the content" do
    test_content = File.read(public_filepath("javascripts/js_1.js"))
    content_size = test_content.length
    minimized_size = BundleFu::JSMinimizer.minimize_content(test_content).length
    
    minimized_size.should > 0
    content_size.should > minimized_size
  end
end
