require 'test/unit'
require "rubygems"
require 'active_support'

for file in ["../init.rb", "../lib/bundle_fu/file_list.rb", "mock_view.rb"]
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end



def dbg
  require 'ruby-debug'
  Debugger.start
  debugger
end



class Object
  def to_regexp
    is_a?(Regexp) ? self : Regexp.new(Regexp.escape(self.to_s))
  end
end