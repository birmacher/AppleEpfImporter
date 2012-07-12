require 'net/http'
require 'date'
require 'apple_epf_importer/protocol'

module AppleEpfImporter
  class AppleEpfDownloader
  
    def download(type, url_path)
      url = [AppleEpfImporter.configuration.itunes_feed_url, url_path].join( "/" )
      start_download( url, [AppleEpfImporter.configuration.extract_dir, File.basename( url_path )].join( "/") )
    end
  
    def get_date_file_name(type, filedate)
      today = DateTime.now
      case type
      when "full"
        # Tar created on every Wednesday
        if filedate == "current"
          date = main_dir_name_by_date( today )
          "current/itunes#{date}.tbz"
        else
          date = main_dir_name_by_date( filedate )
          "#{date}/itunes#{date}.tbz"
        end
      when "incremental"
        if filedate == "current"
          date = date_to_epf_format( today )
          "current/incremental/current/itunes#{date}.tbz"
        else
          main_date = main_dir_name_by_date( today )
          date = date_to_epf_format( filedate )
          "#{main_date}/incremental/#{date}/itunes#{date}.tbz"
        end 
      end 
    end 
  
    private
    
    def main_dir_name_by_date(date)
      days_from_wed = date.wday == 3 ? 0 : 3 - date.wday
      day_diff = days_from_wed > 0 ? days_from_wed - 7 : days_from_wed
      date_of_file = date + day_diff
         
      date_to_epf_format( date_of_file )
    end
    
    def date_to_epf_format(date)
      date.strftime( "%Y%m%d" )
    end
  
    def start_download(url, filename)
      # http://stackoverflow.com/questions/8196325/encoding-error-when-saving-a-document-through-a-rake-task-on-rails
      File.open( filename, "wb" ) do |f|
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
    end
  end
end