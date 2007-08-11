class BundleFu

  class << self
    attr_accessor :content_store
    def init
      @content_store = {}
    end
    
    def bundle_files(filenames=[])
      return nil if filenames.empty?
      
      output = ""
      filenames.each{|filename|
        output << "/* -------------- #{filename} -------------"
        output << "\n"
        output << File.read(File.join(RAILS_ROOT, "public", filename))
        output << "\n"
      }
      output
    end
  end
  
  
  self.init
  
  module InstanceMethods
    # valid options:
    #   :name - The name of the css and js files you wish to output
    # returns true if a regen occured.  False if not.
    def bundle(options={}, &block)
      options = {
        :css_path => "/stylesheets",
        :js_path => "/javascripts",
        :name => "bundle"
      }.merge(options)
      
      content = capture(&block)
      content_changed = false
      
      new_files = nil
      
      # only rescan file list if content_changed
      unless content == BundleFu.content_store[options[:name]]
        BundleFu.content_store[options[:name]] = content 
        new_files = {:js => [], :css => []}
        
        content.scan(/(href|src) *= *["']([^"^'^\?]+)/i).each{ |property, value|
          case property
          when "src"
            new_files[:js] << value
          when "href"
            new_files[:css] << value
          end
        }
      end
      
      
      path = { :css => options[:css_path], :js => options[:js_path] }
#      abs_path = {}
#      filelist = {}
      [:css, :js].each{|filetype|
        abs_path = File.join(RAILS_ROOT, "public", path[filetype], "#{options[:name]}.#{filetype}")
        abs_filelist_path = abs_path + ".filelist"
        filelist = FileList.open( abs_filelist_path )
        
        # check against newly parsed filelist.  If we didn't parse the filelist from the output, then check against the updated ctimes.
        new_filelist = new_files ? BundleFu::FileList.new(new_files[filetype]) : filelist.clone.update_ctimes
        
        unless new_filelist == filelist
          # regenerate everything
          content = BundleFu.bundle_files(new_filelist.filenames) 
          File.open( abs_path, "w") {|f| f.puts content } if content
          new_filelist.save_as(abs_filelist_path)
        end
          
      }
      
      
#      abs_css_path = 
#      abs_js_path = File.join(RAILS_ROOT, "public", options[:js_path], "#{options[:name]}.js")
      
#      filelist = Marshal.load(File.read())

      
      # if the files have changed, rebundle
      
    end
  end
end