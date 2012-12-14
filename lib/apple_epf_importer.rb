require 'tmpdir'

module AppleEpfImporter
  autoload :AppleEpfDownloader, 'apple_epf_importer/apple_epf_downloader'
  autoload :AppleEpfExtractor,  'apple_epf_importer/apple_epf_extractor'
  autoload :AppleEpfParser,     'apple_epf_importer/apple_epf_parser'
  
  class << self
    attr_accessor :configuration
  end
  
  def self.configure
    @configuration ||= Configuration.new
    yield(@configuration) if block_given?
  end
  
  class Configuration
    attr_accessor :apple_id
    attr_accessor :apple_password
    attr_accessor :itunes_feed_url
    attr_accessor :itunes_files
    attr_accessor :extractables
    attr_accessor :extract_dir
    
    def initialize
      @apple_id = ''                                                       # Username
      @apple_password = ''                                                 # Password
      @itunes_feed_url = 'http://feeds.itunes.apple.com/feeds/epf/v3/full' # Base URL
      @itunes_files = [ 'popularity' ]                                     # Tar prefix to download (itunes, popularity,  ...)
      @extractables = [ [ 'application_popularity_per_genre' ] ]           # Files to extract from the tar
                                                                           # multi-dimensional array if needed
      @extract_dir = [Dir.tmpdir, 'epm_files'].join('/')                   # Will create the directories if not exists
    end
  end
  
  # Start to download full EPF import
  # date - export date of EPF file
  # header - header block
  # row - row block
  # success - success block
  def self.get_full_version(date, header, row, success)
    @success = true
    @exception = Array.new
    
    AppleEpfImporter.configuration.itunes_files.each_with_index do |file, index|
      download( "full", file, index, date, header, row )
      
      break unless @success
    end
    
    self.finished( success )
  end

  # Start to download inremental EPF import
  # date - export date of EPF file
  # header - header block
  # row - row block
  # success - success block  
  def self.get_incremental(date, header, row, success)
    @success = true
    
    AppleEpfImporter.configuration.itunes_files.each_with_index do |file, index|
      download( "incremental", file, index, date, header, row )
      
      break unless @success
    end
    
    self.finished( success )
  end
  
  def self.get_file(date, header, row, success)
    @success = true
    
    AppleEpfImporter.configuration.itunes_files.each_with_index do |file, index|
      download( "file", file, index, date, header, row )
      
      break unless @success
    end
    
    self.finished( success )
  end
  
  # Downloader
  def self.downloader
    AppleEpfImporter::AppleEpfDownloader.new
  end
  
  # Extractor
  def self.extractor
    AppleEpfImporter::AppleEpfExtractor.new
  end
  
  # Parser
  def self.parser
    AppleEpfImporter::AppleEpfParser.new
  end
  
  private
  
  def self.download(type, file, index, date, header, row)
    @files_to_parse = AppleEpfImporter.configuration.extractables.at( index )
    download_type( type, file, date, header, row )
  end
  
  def self.extract(filename)
    self.extractor.extract( filename, @files_to_parse )
  end
  
  # Directory
  def self.setup_directory_for_use
    FileUtils.mkpath self.configuration.extract_dir
  end
  
  def self.delete_directory(path)
    FileUtils.rm_rf( path ) if path
  end
  
  def self.delete_file(path)
    FileUtils.rm( path ) if path
  end
  
  # Download
  def self.download_type(type, file, date, header, row)
    begin
      self.setup_directory_for_use
  
      # Download .tbz
      downloader = self.downloader
      url_path = downloader.get_date_file_name( type, file, date )
      
      # Nothing to download
      if url_path.blank?
        p "Nothing to download"
        
        @success = false
        return
      end
      
      p "Download file: #{url_path}"
      p "Download started: #{DateTime.now}"
      
      downloader.download( url_path)
      
      p "Extract started: #{DateTime.now}"
      
      # Extract .tbz
      @extract_path = [self.configuration.extract_dir, File.basename( url_path, '.tbz' )].join('/')
      @extract_file = [self.configuration.extract_dir, File.basename( url_path )].join('/')
      
      self.extract( @extract_file )

      p "Parse started: #{DateTime.now}"
      
      # Parse files
      @files_to_parse.each do |filename|
        p "Parsing file #{filename} started: #{DateTime.now}"
      
        self.parser.parse( [@extract_path, filename].join('/'), header, row )
      end
      
      p "Parse finished: #{DateTime.now}"
      
    # Todo: Don't just for testing
    rescue Exception => ex
#       @exception[ :epf_type ] = type
#       @exception[ :epf_url ] = url_path if url_path
#       @exception[ :extracted_path ] = extract_file if extract_file
#       @exception[ :extracted_file ] = extract_path if extract_path
#       @exception[ :exception_message ] = ex.message
#       @exception[ :exception_backtrace ] = ex.backtrace.join("\n")
    
      puts "===================="
      puts "Exception"
      puts "~~~~~~~~~~~~~~~~~~~~"
      puts "Info"
      puts "Type: #{type}"
      puts "URL: #{url_path}" if url_path
      puts "Extract path: #{@extract_file}" if @extract_file
      puts "Extracted file: #{@extract_path}" if @extract_path
      puts "~~~~~~~~~~~~~~~~~~~~"
      puts ex.message
      puts "===================="
      puts ex.backtrace.join("\n")
    
      @success = false
    ensure
      # Delete the used files
      self.delete_directory( @extract_path ) if @extract_path
      self.delete_file( @extract_file ) if @extract_file
    end
  end
  
  def self.finished(callback)
    callback.call( { :success => @success, :exception => @exception } )
  end
end
