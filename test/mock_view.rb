class MockView
  # set RAILS_ROOT to fixtures dir so we use those files
  include BundleFu::InstanceMethods
  include ActionView::Helpers::AssetTagHelper
  ::RAILS_ROOT = File.join(File.dirname(__FILE__), 'fixtures')
  
  attr_accessor :output
  attr_accessor :session
  attr_accessor :params
  def initialize
    @output = ""
    @session = {}
    @params = {}
  end
  
  def capture(&block)
    yield
  end
  
  def concat(output, *args)
    @output << output
  end
  
  def bundle(options={}, &block)
    @output << (super(options, &block) || "")
  end
end