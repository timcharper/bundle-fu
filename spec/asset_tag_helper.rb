module ActionView
  module Helpers
    module TagHelper
      # stub
    end
    module AssetTagHelper
      
      def stylesheet_link_tag(*args)
        args.collect{|arg| "<link href=\"#{arg}?#{File.mtime(File.join(RAILS_ROOT, 'public', arg)).to_i}\" media=\"screen\" rel=\"Stylesheet\" type=\"text/css\" />" } * "\n"
      end
      
      def javascript_include_tag(*args)
        args.collect{|arg| "<script src=\"#{arg}?#{File.mtime(File.join(RAILS_ROOT, 'public', arg)).to_i}\" type=\"text/javascript\"></script>" } * "\n"
      end
    end
  end
end
