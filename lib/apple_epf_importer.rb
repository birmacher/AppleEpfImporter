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
    self.configuration ||= Configuration.new
#     yield configuration
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
      @apple_id = '4ppwh1rr.c0m'
      @apple_password = '314ed5e5032079b6a1c501ca6a10723a'
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
    
      # Extract .tbz
      @extract_path = [self.configuration.extract_dir, File.basename(url_path)].join('/')
      self.extract( @extract_path )
    
      # Parse files
      self.configuration.extractables.each do |filename|
        self.parser.parse( [@extract_path, filename].join('/'), header, row )
      end
      
#       @success = true
#     rescue
#       @success = false
#     ensure
      # Delete the used directory
      FileUtils.rm_rf( @extract_path ) if @extract_path
      
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
end
