class BundleFu

  class << self
    attr_accessor :content_store
    def init
      @content_store = {}
    end
    
    def each_read_file(filenames=[])
      filenames.each{ |filename|
        output  = "/* -------------- #{filename} ------------- */ "
        output << "\n"
        output << (File.read(File.join(RAILS_ROOT, "public", filename)) rescue ( return "/* FILE READ ERROR! */"))
        output << "\n"
        yield filename, output
      }
    end
    
    def bundle_js_files(filenames=[], output_filename = "", options={})
      output = ""
      each_read_file(filenames) { |filename, content|
      }
    end
    
    def rewrite_relative_path(old_filename, new_filename)
      
    end
  
    def bundle_css_files(filenames=[], output_filename = "", options = {})
      output = ""
      each_read_file(filenames) { |filename, content|
        # rewrite the URL reference paths
        # url(../../../images/active_scaffold/default/add.gif);
        # url(/stylesheets/active_scaffold/default/../../../images/active_scaffold/default/add.gif);
        # url(/stylesheets/active_scaffold/../../images/active_scaffold/default/add.gif);
        # url(/stylesheets/../images/active_scaffold/default/add.gif);
        # url(/images/active_scaffold/default/add.gif);
        
        output << self.send("sanitized_#{options[:type]}", options)
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
      # allow bypassing via the querystring
      session[:bundle_fu] = (params[:bundle_fu]=="true") if params.has_key?(:bundle_fu)
      
      options = {
        :css_path => ($bundle_css_path || "/stylesheets/cache"),
        :js_path => ($bundle_js_path || "/javascripts/cache"),
        :name => ($bundle_default_name || "bundle"),
        :bundle_fu => ( session[:bundle_fu].nil? ? ($bundle_fu.nil? ? true : $bundle_fu) : session[:bundle_fu] )
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
            js_files[:js] << value
          when "href"
            css_files[:css] << value
          end
        }
      end
         
      [:css, :js].each { |filetype|
        output_filename = File.join(paths[filetype], "#{options[:name]}.#{filetype}")
        abs_path = File.join(RAILS_ROOT, "public", output_filename)
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
            BundleFu.send("bundle_#{filelist}_files", new_filelist.filenames, output_filename)
#            output = BundleFu.bundle_files(new_filelist.filenames, :type => filetype) 
#            File.open( abs_path, "w") {|f| f.puts output } if output
          end
          new_filelist.save_as(abs_filelist_path)
        end
        
        if File.exists?(abs_path) && options[:bundle_fu]
          concat( filetype==:css ? stylesheet_link_tag(output_filename) : javascript_include_tag(output_filename), block.binding)
        end
      }
      
      unless options[:bundle_fu]
        concat( content, block.binding )
      end
    end
  end
end