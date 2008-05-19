require "rubygems"
require 'active_support'
require 'erb'
for file in ["asset_tag_helper", "../environment.rb", "mock_view.rb"]
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end

class Object
  def to_regexp
    is_a?(Regexp) ? self : Regexp.new(Regexp.escape(self.to_s))
  end
end

CONTENT_INCLUDE_SOME = <<-EOF
<script src="/javascripts/js_1.js?1000" type="text/javascript"></script>
<script src="/javascripts/js_2.js?1000" type="text/javascript"></script>
<link href="/stylesheets/css_1.css?1000" media="screen" rel="Stylesheet" type="text/css" />
<link href="/stylesheets/css_2.css?1000" media="screen" rel="Stylesheet" type="text/css" />
EOF
  
  # the same content, slightly changed
CONTENT_INCLUDE_ALL = CONTENT_INCLUDE_SOME + <<-EOF
<script src="/javascripts/js_3.js?1000" type="text/javascript"></script>
<link href="/stylesheets/css_3.css?1000" media="screen" rel="Stylesheet" type="text/css" />
EOF
  
def public_filepath(filename)
  s = File.join(::RAILS_ROOT, "public", filename)
end

def public_files_contents(filenames)
  filenames.map { |f| public_file_contents(f) }
end

def public_file_contents(filename)
  File.read(public_filepath(filename))
end

class Object
  def each_should(*args)
    each {|item| item.should(*args)}
  end
  
  def each_should_not(*args)
    each {|item| item.should_not(*args)}
  end
end