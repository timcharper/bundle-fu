class MockView
  # set RAILS_ROOT to fixtures dir so we use those files
  include BundleFu::InstanceMethods
  ::RAILS_ROOT = File.join(File.dirname(__FILE__), 'fixtures')
  
  def capture(&block)
    yield
  end
end