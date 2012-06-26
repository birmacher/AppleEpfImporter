require 'net/http'
require 'date'

load 'lib/loggable.rb'

class AppleEpfDownloader
  include Loggable
  
  def download(type, url_path)
    url = [AppleEpfImporter.configuration.itunes_feed_url, self.get_date_file_name(type)].join('/')
    
    start_download( url, [AppleEpfImporter.configuration.extract_dir, File.basename( url_path )].join('/') )
  end
  
  # TODO: only current parsed
  def get_date_file_name(type)
    today = DateTime.now
    case type
    when 'full'
#      if @filedate == "current"
        days_from_wed = today.wday == 3 ? 0 : 3 - today.wday
        day_diff = days_from_wed > 0 ? days_from_wed - 7 : days_from_wed
        date_of_file = today + day_diff
        'current/itunes' + date_of_file.strftime('%Y%m%d') + '.tbz'
#      else
#        "#{@filedate}/itunes#{@filedate}.tbz"
#      end
    when 'incremental'
#      if @filedate == "current"
        'current/incremental/current/itunes' + today.strftime('%Y%m%d') + '.tbz'
#       else
#         # TODO: implement this
#         ""
#      end 
    end 
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
# TODO: CHECK WITHOUT SLEEP. FASTER?
# FASTER -> setup a buffer for lowering CPU %
#              sleep 0.005
            end
          end
        end
      end
      logger.info 'Finished to download ' + url + ' to ' + filename
#    rescue
#      logger.warn 'Error while downloading ' + url
#    end
  end
end