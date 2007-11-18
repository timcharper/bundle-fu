class BundleFu
  include ERB::Util
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper

  cattr_accessor :content_store, :default_name, :js_path, :css_path
  self.content_store = {}
  
  def initialize(content, options = {})
    @content = content
    @new_files = nil
    @paths = { :css => options[:css_path], :js => options[:js_path] }
    @options = options
    @tag_output = ""
  end
  
  def abs_filelist_paths(filetype)
    @abs_filelist_paths ||= {}
    @abs_filelist_paths[filetype] ||= File.join(RAILS_ROOT, "public", @paths[filetype], "#{@options[:name]}.#{filetype}.filelist");
  end
  
  class << self
    def reset!
      self.content_store = {}
      self.default_name = self.js_path = self.css_path = nil
    end
    def prevent_memory_leak
      if BundleFu.content_store.length > 100
        BundleFu.content_store.clear
        # TODO - inform the user they've got too many name combinations and that they would've had a memory leak, had we not intervened.
      end
    end
    
    def extract_asset_files(content)
      asset_files = {:js => [], :css => []}
      
      content.scan(/(href|src) *= *["']([^"^'^\?]+)/i).each{ |property, value|
        case property
        when "src"
          asset_files[:js] << value
        when "href"
          asset_files[:css] << value
        end
      }
      asset_files
    end
  end
    
  def bundle_files(filenames=[], &block)
    output = ""
    filenames.each{ |filename|
      output << "/* --------- #{filename} --------- */ "
      output << "\n"
      begin
        content = (File.read(File.join(RAILS_ROOT, "public", filename)))
      rescue 
        output << "/* FILE READ ERROR! */"
        next
      end
      
      output << (yield(filename, content)||"")
    }
    output
  end
  
  def bundle_js_files(filenames=[])
    output = 
    bundle_files(filenames) { |filename, content|
      if @options[:compress]
        if Object.const_defined?("Packr")
          content
        else
          JSMinimizer.minimize_content(content)
        end
      else
        content
      end
    }
    
    if Object.const_defined?("Packr")
      # use Packr plugin (http://blog.jcoglan.com/packr/)
      Packr.new.pack(output, @options[:packr_options] || {:shrink_vars => false, :base62 => false})
    else
      output
    end
    
  end

  def bundle_css_files(filenames=[])
    bundle_files(filenames) { |filename, content|
      BundleFu::CSSUrlRewriter.rewrite_urls(filename, content)
    }
  end
  
  
  def content_changed?; @content != BundleFu.content_store[@options[:name]]; end
  
  def filelist_cache_missing?
    !File.exists?(abs_filelist_paths(:css)) || !File.exists?(abs_filelist_paths(:js))
  end
  
  def update_content_cache
    BundleFu.content_store[@options[:name]] = @content
    BundleFu.prevent_memory_leak
  end

  def process
    # only rescan file list if content_changed, or if a filelist cache file is missing
    
    @cached_filelists = {
      :js => FileList.open(abs_filelist_paths(:js)),
      :css => FileList.open(abs_filelist_paths(:css)),
    }
    
    if content_changed? || filelist_cache_missing?
      update_content_cache
      asset_files = BundleFu.extract_asset_files(@content)
      @current_filelists = {
        :js => FileList.new(asset_files[:js]),
        :css => FileList.new(asset_files[:css])
      }
    else
      # use filelists from cache
      @current_filelists = {
        :js => @cached_filelists[:js].clone.update_mtimes,
        :css => @cached_filelists[:css].clone.update_mtimes
      }
    end
    
    [:css, :js].each { |filetype| process_type(filetype) }
    
    @tag_output
  end
  
protected  
  def bundle_filename(filetype = :js)
    @bundle_filenames||={}
    @bundle_filenames[filetype]||= File.join(@paths[filetype], "#{@options[:name]}.#{filetype}")
  end
  
  def abs_bundle_filename(filetype = :js)
    @abs_bundle_filenames||={}
    @abs_bundle_filenames[filetype]||=File.join(RAILS_ROOT, "public", bundle_filename(filetype))
  end
  
  def abs_path(filetype)
    File.join(RAILS_ROOT, "public", @paths[filetype])
  end
  
  def process_type(filetype = :js)
    output_filename = bundle_filename(filetype)
    abs_filelist_path = abs_filelist_paths(filetype)
    
    current_filelist = @current_filelists[filetype]
    
    unless current_filelist == @cached_filelists[filetype]
      FileUtils.mkdir_p(abs_path(filetype))
      
      if current_filelist.filenames.empty?
        # delete the javascript/css bundle file if it's empty, but keep the cached_filelist
        FileUtils.rm_f(abs_bundle_filename(filetype))
      else
        # call bundle_css_files or bundle_js_files to bundle all files listed.  output it's contents to a file
        bundled_output = send("bundle_#{filetype}_files", current_filelist.filenames)
        if bundled_output
          File.open( abs_bundle_filename(filetype), "w") {|f| f.puts bundled_output }
        end
      end
      current_filelist.save_as(abs_filelist_path)
    end
    
    @tag_output << ( filetype==:css ? stylesheet_link_tag(output_filename) : javascript_include_tag(output_filename) ) if File.exists?(abs_bundle_filename(filetype))
    
  end
  
  
  module InstanceMethods
    # valid options:
    #   :name - The name of the css and js files you wish to output
    # returns true if a regen occured.  False if not.
    def bundle(options={}, &block)
      options = process_bundle_options(options)
      
      if options[:bundle_fu]
        content = capture(&block)
        bundle_fu = BundleFu.new(content, options)
        
        concat bundle_fu.process, block.binding
        nil
      else
        yield
      end
    end
    
  protected
    def process_bundle_options(options)
      # allow bypassing via the querystring
      session[:bundle_fu] = (params[:bundle_fu]=="true") if params.has_key?(:bundle_fu)
      
      options = {
        :css_path => (BundleFu.css_path || "/stylesheets/cache"),
        :js_path => (BundleFu.js_path  || "/javascripts/cache"),
        :name => (BundleFu.default_name || "bundle"),
        :compress => true,
        :bundle_fu => session[:bundle_fu].nil? ? true : session[:bundle_fu]
      }.merge(options)
      
      options[:bundle_fu] = !options[:bypass] unless options[:bypass].nil?
      options
    end
    
    
  end
end