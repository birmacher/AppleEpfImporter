require 'net/http'

load 'lib/loggable.rb'

class AppleEpfDownloader
  include Loggable
  
  def download(type, filename, save_to)
    path = [AppleEpfImporter.configuration.itunes_feed_url]
    path.push 'incremental/current' if type.eql? 'incremental'
    path.push filename
    url = path.join('/')
    
    start_download( url, save_to )
  end
  
  private
  
  def start_download(url, filename)
    puts 'URL: ' + url
    puts 'File: ' + filename
#    begin
      logger.info 'Started to download ' + url
      File.open( filename, 'w' ) do |f|
        uri = URI.parse url
      
        username = AppleEpfImporter.configuration.apple_id
        password = AppleEpfImporter.configuration.apple_password
        
        Net::HTTP.start( uri.host, uri.port ) do |http|
          req = Net::HTTP::Get.new( uri.path )
          req.basic_auth username, password
          
          http.request( req ) do |res|
            res.read_body do |seg|
              f << seg
              # Sleep a bit to let the buffer top up
              sleep 0.005
            end
          end
        end
      end
      logger.info 'Finished to download ' + url + ' to ' + filename
#    rescue
      logger.warn 'Error while downloading ' + url
#    end
  end
end