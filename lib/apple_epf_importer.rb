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
    attr_accessor :read_buffer_size
    attr_accessor :read_timeout
    
    def initialize
      @apple_id = '4ppwh1rr.c0m'                                           # Username
      @apple_password = '314ed5e5032079b6a1c501ca6a10723a'                 # Password
      @itunes_feed_url = 'http://feeds.itunes.apple.com/feeds/epf/v3/full' # Base URL
      @itunes_files = [ 'popularity']                                      # Tar prefix to download (itunes, popularity,  ...)
      @extractables = [ [ 'application_popularity_per_genre' ] ]           # Files to extract from the tar
                                                                           # multi-dimensional array if needed
      @extract_dir = [Dir.tmpdir, 'epm_files'].join('/')                   # Will create the directories if not exists
      @read_buffer_size = 32768
      @read_timeout = 60
    end
  end
  
  def self.get_full_version(date, header, row, success)
    @success = true
    
    AppleEpfImporter.configuration.itunes_files.each_with_index do |file, index|
      download( "full", file, index, date, header, row )
      
      break unless @success
    end
    
    success.call( @success )
  end
  
  def self.get_incremental(date, header, row, success)
    @success = true
    
    AppleEpfImporter.configuration.itunes_files.each_with_index do |file, index|
      download( "incremental", file, index, date, header, row )
      
      break unless @success
    end
    
    success.call( @success )
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
      downloader.download( type, url_path)
      
      # Extract .tbz
      @extract_path = [self.configuration.extract_dir, File.basename( url_path, '.tbz' )].join('/')
      @extract_file = [self.configuration.extract_dir, File.basename( url_path )].join('/')
      
      self.extract( @extract_file )
      
      # Parse files
      @files_to_parse.each do |filename|
        self.parser.parse( [@extract_path, filename].join('/'), header, row )
      end
      
    # Todo: Don't just for testing
    rescue Exception => ex
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
end
