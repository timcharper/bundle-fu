require File.join(File.dirname(__FILE__), '../test_helper.rb')

require "test/unit"

# require "library_file_name"

class BundleFuTest < Test::Unit::TestCase
  @@content_include_some = <<-EOF
  <script src="/javascripts/js_1.js?1000" type="text/javascript"></script>
  <script src="/javascripts/js_2.js?1000" type="text/javascript"></script>
  <link href="/stylesheets/css_1.css?1000" media="screen" rel="Stylesheet" type="text/css" />
  <link href="/stylesheets/css_2.css?1000" media="screen" rel="Stylesheet" type="text/css" />
  EOF
  
  # the same content, slightly changed
  @@content_include_all = @@content_include_some + <<-EOF
  <script src="/javascripts/js_3.js?1000" type="text/javascript"></script>
    <link href="/stylesheets/css_3.css?1000" media="screen" rel="Stylesheet" type="text/css" />
  EOF

  
  def setup
    @mock_view = MockView.new
    BundleFu.init # resets BundleFu
  end
  
  def teardown
    purge_cache
  end
  
  def test__content_remains_same__shouldnt_refresh_cache
    @mock_view.bundle { @@content_include_some }
    
    # check to see each bundle file exists and append some text to the bottom of each file
    append_to_public_files(cache_files("bundle"), "BOGUS")
    
    assert_public_files_match("/javascripts/bundle.js", "BOGUS")
    assert_public_files_match("/stylesheets/bundle.css", "BOGUS")
    
    @mock_view.bundle { @@content_include_some }
    
    assert_public_files_match("/javascripts/bundle.js", "BOGUS")
    assert_public_files_match("/stylesheets/bundle.css", "BOGUS")
  end
  
  def test__content_changes__should_refresh_cache
    @mock_view.bundle { @@content_include_some }
    
    # check to see each bundle file exists and append some text to the bottom of each file
    append_to_public_files(cache_files("bundle"), "BOGUS")
    assert_public_files_match(cache_files("bundle"), "BOGUS")
    
    # now, pass in some new content.  Make sure that the css/js files are regenerated
#    dbg
    @mock_view.bundle { @@content_include_all }
    assert_public_files_no_match(cache_files("bundle"), "BOGUS")
    assert_public_files_no_match(cache_files("bundle"), "BOGUS")
  end
  
  def test__modified_time_differs_from_file__should_refresh_cache
    @mock_view.bundle { @@content_include_some }
    # we're gonna hack each of them and set all the modified times to 0
    cache_files("bundle").each{|filename|
      abs_filelist_path = public_file(filename + ".filelist")
#      dbg  
      b = BundleFu::FileList.open(abs_filelist_path)
      b.filelist.each{|entry| entry[1] = entry[1] - 100 }
      b.save_as(abs_filelist_path)
    }
    
    append_to_public_files(cache_files("bundle"), "BOGUS")
  end
  
  def test__content_remains_same_but_cache_files_dont_match_whats_in_content__shouldnt_refresh_cache
    # it shouldnt parse the content unless if it differed from the last request.  This scenario should never exist, and if it did it would be fixed when the server reboots.
    @mock_view.bundle { @@content_include_some }
    abs_filelist_path = public_file("/stylesheets/bundle.css.filelist")
    b = BundleFu::FileList.open(abs_filelist_path)
    
    @mock_view.bundle { @@content_include_all }
    b.save_as(abs_filelist_path)
    append_to_public_files(cache_files("bundle"), "BOGUS")
    
    @mock_view.bundle { @@content_include_all }
    assert_public_files_match(cache_files("bundle"), "BOGUS")
    
  end
  
  def test__content_differs_slightly_but_cache_files_match__shouldnt_refresh_cache
    @mock_view.bundle { @@content_include_all }
    append_to_public_files(cache_files("bundle"), "BOGUS")
    @mock_view.bundle { @@content_include_all + "  " }
    assert_public_files_match(cache_files("bundle"), "BOGUS")
  end
  
private
  def public_file(filename)
    File.join(MockView::RAILS_ROOT, "public", filename)
  end
  
  def purge_cache
    # remove all fixtures named "bundle*"
    Dir[ public_file("**/bundle*") ].each{|filename| FileUtils.rm_f filename }
  end
  
  def assert_public_file_exists(filename, message=nil)
    assert_file_exists(public_file(filename), message)
  end
  
  def assert_file_exists(filename, message=nil)
    assert(File.exists?(filename), message || "File #{filename} expected to exist, but didnt.")
  end
  
  def assert_public_files_match(filenames, needle, message=nil)
    filenames.each{|filename|
      assert_public_file_exists(filename)
      assert_match(needle.to_regexp, File.read(public_file(filename)), message || "expected #{filename} to match #{needle}, but doesn't.")
    }
  end
  
  def assert_public_files_no_match(filenames, needle, message=nil)
    filenames.each{ |filename|
      assert_public_file_exists(filename)
      assert_no_match(needle.to_regexp, File.read(public_file(filename)), message || "expected #{filename} to not match #{needle}, but does.")
    }
  end
  
  def cache_files(name)
    ["/javascripts/#{name}.js", "/stylesheets/#{name}.css"]
  end

  def append_to_public_files(filenames, content)
    for filename in filenames
      assert_public_file_exists(filename)
      File.open(public_file(filename), "a") {|f|
        f.puts(content)
      }
    end
  end  
end