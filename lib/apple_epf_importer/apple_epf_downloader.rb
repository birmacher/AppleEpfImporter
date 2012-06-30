require 'net/http'
require 'date'
require 'apple_epf_importer/protocol'

module AppleEpfImporter
  class AppleEpfDownloader
#     include Loggable
  
    def download(type, url_path)
      url = [AppleEpfImporter.configuration.itunes_feed_url, url_path].join('/')
    
      start_download( url, [AppleEpfImporter.configuration.extract_dir, File.basename( url_path )].join('/') )
    end
  
    # TODO: only current parsed
    def get_date_file_name(type, filedate)
      today = DateTime.now
      case type
      when 'full'
       if filedate == 'current'
         days_from_wed = today.wday == 3 ? 0 : 3 - today.wday
         day_diff = days_from_wed > 0 ? days_from_wed - 7 : days_from_wed
         date_of_file = today + day_diff
         'current/itunes' + date_of_file.strftime('%Y%m%d') + '.tbz'
       else
         filedate.strftime('%Y%m%d') + '/itunes' + filedate.strftime('%Y%m%d') + '.tbz'
       end
      when 'incremental'
       if filedate == 'current'
         'current/incremental/current/itunes' + today.strftime('%Y%m%d') + '.tbz'
       else
#         # TODO: Not in current dir too
         'current/incremental/current/itunes' + filedate.strftime('%Y%m%d') + '.tbz'
       end 
      end 
    end 
  
    private
  
    def start_download(url, filename)
#        puts 'URL: ' + url
#       puts 'File: ' + filename
    
#      begin
        # logger.info 'Started to download ' + url
        # http://stackoverflow.com/questions/8196325/encoding-error-when-saving-a-document-through-a-rake-task-on-rails
        File.open( filename, "wb" ) do |f|
          puts "URL: #{url}"
          puts "Downloading file to: #{f.path}"
          
          uri = URI.parse url
      
          username = AppleEpfImporter.configuration.apple_id
          password = AppleEpfImporter.configuration.apple_password
        
          Net::HTTP.start( uri.host, uri.port ) do |http|
            req = Net::HTTP::Get.new( uri.path )
            req.basic_auth username, password
          
            http.request( req ) do |res|
              res.read_body do |seg|
                f << seg
              end
            end
          end
        end
        # logger.info 'Finished to download ' + url + ' to ' + filename
#      rescue
       # logger.warn 'Error while downloading ' + url
#      end
    end
  end
end