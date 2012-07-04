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
    attr_accessor :extractables
    attr_accessor :extract_dir
    attr_accessor :read_buffer_size
    attr_accessor :read_timeout
    
    def initialize
      @apple_id = ''
      @apple_password = ''
      @itunes_feed_url = 'http://feeds.itunes.apple.com/feeds/epf/v3/full'
      @extractables = [ 'application', 'application_detail', 'application_device_type', 'artist_application', 'genre_application', 'storefront']
      @extract_dir = [Dir.tmpdir, 'epm_files'].join('/') # Will create the directories if not exists,
                                                         # And (TODO!) remove it content
      @read_buffer_size = 32768
      @read_timeout = 60
    end
  end
  
  def self.get_full_version(date, header, row, success)
    download_type( "full", date, header, row, success )
  end
  
  def self.get_incremental(date, header, row, success)
    download_type( "incremental", date, header, row, success )
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
  
  def self.extract(filename)
    self.extractor.extract( filename )
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
  def self.download_type(type, date, header, row, success)
    begin
      self.setup_directory_for_use
  
      # Download .tbz
      downloader = self.downloader
      url_path = downloader.get_date_file_name( type, date )
      downloader.download( type, url_path)
      
      # Extract .tbz
      @extract_path = [self.configuration.extract_dir, File.basename( url_path, '.tbz' )].join('/')
      @extract_file = [self.configuration.extract_dir, File.basename( url_path )].join('/')
      
      self.extract( @extract_file )
      
      # Parse files
      AppleEpfImporter.configuration.extractables.each do |filename|
        self.parser.parse( [@extract_path, filename].join('/'), header, row )
      end
      
      @success = true
    rescue Exception => ex
      puts "===================="
      puts "Exception"
      puts "~~~~~~~~~~~~~~~~~~~~"
      puts "Info"
      puts "Type: #{type}"
      puts "URL: #{url_path}" if url_path
      puts "Extract path: #{@extract_file}" if extract_file
      puts "Extracted file: #{@extract_path}" if extract_path
      puts "~~~~~~~~~~~~~~~~~~~~"
      puts ex.message
      puts "===================="
      puts ex.backtrace.join("\n")
    
      @success = false
    ensure
      # Delete the used files
      self.delete_directory( @extract_path ) if @extract_path
      self.delete_file( @extract_file ) if @extract_file
      
      success.call( @success )
    end
  end
end
