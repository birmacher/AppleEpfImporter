require 'tmpdir'

module AppleEpfImporter
#   autoload 'loggable.rb'
#  autoload 'protocol.rb'
  autoload :AppleEpfDownloader, 'apple_epf_importer/apple_epf_downloader'
  autoload :AppleEpfExtractor,  'apple_epf_importer/apple_epf_extractor'
  autoload :AppleEpfParser,     'apple_epf_importer/apple_epf_parser'

#   include Loggable
  
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
  
  def self.get_incremental(date, header, row, success)
#     begin
      self.setup_directory_for_use
  
      # Download .tbz
      downloader = self.downloader
      url_path = downloader.get_date_file_name( 'incremental', date )
      downloader.download( 'incremental', url_path)
      
      puts "-> File downloaded"
    
      # Extract .tbz
      @extract_file = [self.configuration.extract_dir, File.basename( url_path, '.tbz' )].join('/')
      @extract_path = [self.configuration.extract_dir, File.basename( url_path )].join('/')
      
      puts "-> extracting file: #{@extract_file}"
      puts "-> extracting path: #{@extract_path}"
      
      # Clean up the directory
      self.delete_directory( AppleEpfImporter.configuration.extract_dir )
      self.extract( @extract_path )
      
      puts "-> extracted file"
    
      # Parse files
      AppleEpfImporter.configuration.extractables.each do |filename|
        puts "-> started parsing: #{filename}"
        self.parser.parse( [@extract_file, filename].join('/'), header, row )
      end
      
#       @success = true
#     rescue
#       @success = false
#     ensure
      # Delete the used directory
      puts "-> delete directory"
      self.delete_directory( AppleEpfImporter.configuration.extract_dir )
      
      puts "-> end"
#       success.call( @success )
      success.call( true )
#     end
  end
  
  def self.extract(filename)
    self.extractor.extract( filename )
  end
  
  def self.parse(filename)
    self.parser.parse( filename )
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
  
  # Directory
  def self.setup_directory_for_use
    FileUtils.mkpath self.configuration.extract_dir
    # Todo: empty directory
  end
  
  def self.delete_directory(path)
    FileUtils.rm_rf( path ) if path
  end
end
