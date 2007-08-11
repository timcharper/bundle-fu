# EZ Bundle
for file in ["/lib/bundle_fu.rb", "/lib/bundle_fu/file_list.rb"]
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end

ActionView::Base.send(:include, BundleFu::InstanceMethods)