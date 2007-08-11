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
        output << "/* -------------- #{filename} ------------- */ "
        output << "\n"
        output << (File.read(File.join(RAILS_ROOT, "public", filename)) rescue "/* FILE READ ERROR! */")
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
        :css_path => ($bundle_css_path || "/stylesheets/cache"),
        :js_path => ($bundle_js_path || "/javascripts/cache"),
        :name => ($bundle_default_name || "bundle"),
        :bypass => ($bundle_bypass || false)
      }.merge(options)
      
      paths = { :css => options[:css_path], :js => options[:js_path] }
      
      content = capture(&block)
      content_changed = false
      
      new_files = nil
      abs_filelist_paths = [:css, :js].inject({}) { | hash, filetype | hash[filetype] = File.join(RAILS_ROOT, "public", paths[filetype], "#{options[:name]}.#{filetype}.filelist"); hash }
      
      # only rescan file list if content_changed, or if a filelist cache file is missing
      unless content == BundleFu.content_store[options[:name]] && File.exists?(abs_filelist_paths[:css]) && File.exists?(abs_filelist_paths[:js])
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
         
      [:css, :js].each { |filetype|
        path = File.join(paths[filetype], "#{options[:name]}.#{filetype}")
        abs_path = File.join(RAILS_ROOT, "public", path)
        abs_filelist_path = abs_filelist_paths[filetype]
        
        filelist = FileList.open( abs_filelist_path )
        
        # check against newly parsed filelist.  If we didn't parse the filelist from the output, then check against the updated mtimes.
        new_filelist = new_files ? BundleFu::FileList.new(new_files[filetype]) : filelist.clone.update_mtimes
        
        unless new_filelist == filelist
          FileUtils.mkdir_p(File.join(RAILS_ROOT, "public", paths[filetype]))
          # regenerate everything
          if new_filelist.filenames.empty?
            # delete the javascript/css bundle file if it's empty, but keep the filelist cache
            FileUtils.rm_f(abs_path)
          else
            output = BundleFu.bundle_files(new_filelist.filenames) 
            File.open( abs_path, "w") {|f| f.puts output } if output
          end
          new_filelist.save_as(abs_filelist_path)
        end
        
        if File.exists?(abs_path) && !options[:bypass]
          concat( filetype==:css ? stylesheet_link_tag(path) : javascript_include_tag(path), block.binding)
        end
      }
      
      if options[:bypass]
        concat( content, block.binding )
      end
    end
  end
end