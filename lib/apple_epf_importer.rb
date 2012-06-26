load 'lib/loggable.rb'
load 'lib/apple_epf_downloader.rb'

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
    
    def initialize
      @apple_id = '4ppwh1rr.c0m'
      @apple_password = '314ed5e5032079b6a1c501ca6a10723a'
      @itunes_feed_url = 'http://feeds.itunes.apple.com/feeds/epf/v3/full/current'
    end
  end
  
  def self.get_incremental
    filename = '/Users/birmacher/Desktop/' + Time.now.to_i.to_s + '.tbz'
  
    download = self.downloader
    downloader.download( 'incremental', 'itunes20120626.tbz', filename)
  end
  
  # Downloader
  def self.downloader
    AppleEpfDownloader.new
  end
end
