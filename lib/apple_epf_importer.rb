require 'tmpdir'

load 'lib/loggable.rb'
load 'lib/apple_epf_downloader.rb'
load 'lib/apple_epf_extractor.rb'

module AppleEpfImporter
  include Loggable
  
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
    
    def initialize
      @apple_id = '4ppwh1rr.c0m'
      @apple_password = '314ed5e5032079b6a1c501ca6a10723a'
      @itunes_feed_url = 'http://feeds.itunes.apple.com/feeds/epf/v3/full'
      @extractables = [ 'application', 'application_detail', 'application_device_type', 'artist_application', 'genre_application', 'storefront']
      @extract_dir = [Dir.tmpdir, 'epm_files'].join('/') # Will create the directories if not exists,
                                                         # And (TODO!) remove it content
    end
  end
  
  def self.get_incremental
    self.setup_directory_for_use
    
    puts 'start downloading incremental'
  
    downloader = self.downloader
    url_path = downloader.get_date_file_name('incremental')
    
    puts 'from: ' + url_path
    
    downloader.download( 'incremental', url_path)
    
    puts 'start extracting file: ' + [self.configuration.extract_dir, File.basename(url_path)].join('/')
    
    self.extract( [self.configuration.extract_dir, File.basename(url_path)].join('/') )
  end
  
  def self.extract(filename)
    self.extractor.extract(filename)
  end
    
  # Downloader
  def self.downloader
    AppleEpfDownloader.new
  end
  
  # Extractor
  def self.extractor
    AppleEpfExtractor.new
  end
  
  private 
  
  # Directory
  def self.setup_directory_for_use
    FileUtils.mkpath self.configuration.extract_dir
    # Todo: empty directory
  end
end
