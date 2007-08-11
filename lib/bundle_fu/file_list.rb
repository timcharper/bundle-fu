require 'fileutils.rb'

class BundleFu::FileList
  attr_accessor :filelist
  
  def initialize(filenames=[])
    self.filelist = []
    
    self.add_files(filenames)
  end
  
  def initialize_copy(from)
    self.filelist = from.filelist.collect{|entry| entry.clone}
  end
  
  def filenames
    self.filelist.collect{ |entry| entry[0] }
  end
  
  def update_ctimes
    old_filenames = self.filenames
    self.filelist = []
    # readding the files will effectively update the ctimes
    self.add_files(old_filenames)
    self
  end
  
  def self.open(filename)
    b = new
    b.filelist = Marshal.load(File.read(filename)) if File.exists?(filename)
    b
  end
  
  # compares to see if one file list is exactly the same as another
  def ==(compare)
    throw "cant compare with #{compare.class}" unless self.class===compare
    
    self.filelist == compare.filelist
  end
  
  def add_files(filenames=[])
    filenames.each{|filename|
      self.filelist << [ filename, File.ctime(abs_location(filename)).to_i ]
    }
  end
  
  def save_as(filename)
    File.open(filename, "w") {|f| f.puts Marshal.dump(self.filelist)}
  end
protected
  def abs_location(filename)
    File.join(RAILS_ROOT, "public", filename)
  end
end
