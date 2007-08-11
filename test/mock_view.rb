class MockView
  # set RAILS_ROOT to fixtures dir so we use those files
  include BundleFu::InstanceMethods
  ::RAILS_ROOT = File.join(File.dirname(__FILE__), 'fixtures')
  
  attr_accessor :output
  
  def initialize
    @output = ""
  end
  
  def capture(&block)
    yield
  end
  
  def concat(output, *args)
    @output << output
  end
  
  def stylesheet_link_tag(*args)
    args.collect{|arg| "<link href=\"#{arg}?#{File.ctime(File.join(RAILS_ROOT, 'public', arg)).to_i}\" media=\"screen\" rel=\"Stylesheet\" type=\"text/css\" />" } * "\n"
  end
  
  def javascript_include_tag(*args)
    args.collect{|arg| "<script src=\"#{arg}?#{File.ctime(File.join(RAILS_ROOT, 'public', arg)).to_i}\" type=\"text/javascript\"></script>" } * "\n"
  end
end