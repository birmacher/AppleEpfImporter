require 'net/http'
require 'date'
require 'curb'

module AppleEpfImporter
  class AppleEpfDownloader
  
    def download(url_path)
      url = File.join( AppleEpfImporter.configuration.itunes_feed_url, url_path )
      download_to = File.join( AppleEpfImporter.configuration.extract_dir, File.basename( url_path ) )
      
      p "Download file: #{url}"
      p "Download to: #{download_to}"
      
      start_download( url, download_to )
    end
  
    def get_date_file_name(type, file, filedate)
      today = DateTime.now
      case type
      when "full"
        # Tar created on every Wednesday
        if filedate == "current"
          date = main_dir_name_by_date( today )
          "current/#{file}#{date}.tbz"
        else
          date = main_dir_name_by_date( filedate )
          "#{date}/#{file}#{date}.tbz"
        end
      when "incremental"
        if filedate == "current"
          date = date_to_epf_format( today )
          "current/incremental/current/#{file}#{date}.tbz"
        else
          main_date = main_dir_name_by_date( filedate, true )
          date = date_to_epf_format( filedate )
          "#{main_date}/incremental/#{date}/#{file}#{date}.tbz"
        end
      when "file"
        date = date_to_epf_format( filedate )
        "#{file}#{date}.tbz"
      end
    end 
  
    private
    
    def main_dir_name_by_date(date, inc=false)
      days_from_wed = date.wday == 3 ? 0 : 3 - date.wday
      day_diff = days_from_wed > 0 ? days_from_wed - 7 : days_from_wed
      date_of_file = date + day_diff
      date_of_file -= 7 if inc && date_of_file.to_date == date.to_date # The incremental file is stored in the previous dir...
         
      date_to_epf_format( date_of_file )
    end
    
    def date_to_epf_format(date)
      date.strftime( "%Y%m%d" )
    end
  
    def start_download(url, filename)
      begin
        curl = Curl::Easy.new( url )
        
        # Authentication
        curl.http_auth_types = :basic
        curl.username = AppleEpfImporter.configuration.apple_id
        curl.password = AppleEpfImporter.configuration.apple_password
        
        File.open(filename, 'wb') do |f|
          curl.on_body { |data| f << data; }   
          curl.perform
        end
      rescue Exception => ex
        # Allow Curl::Err::PartialFileError
        unless ex.eql? Curl::Err::PartialFileError
          raise ex
        end
      end
    end
  end
end