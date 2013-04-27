require 'net/http'
require 'date'
require 'curb'

module AppleEpfImporter
  class AppleEpfDownloader
  
    def download(url_path)
      url = full_url( url_path )
      download_to = File.join( AppleEpfImporter.configuration.extract_dir, File.basename( url_path ) )
      
      p "Download file: #{url}"
      p "Download to: #{download_to}"
      
      @download_retry = 0
      start_download( url, download_to )
    end
  
    def get_date_file_name(type, file, filedate, check_if_in_previous_week = false, check_if_in_thursday = false)
      today = DateTime.now
      url = ""
      case type
      when "full"
        # Tar created on every Wednesday
        if filedate == "current"
          date = main_dir_name_by_date( today, false, check_if_in_previous_week, check_if_in_thursday )
          url = "current/#{file}#{date}.tbz"
        else
          date = main_dir_name_by_date( filedate, false, check_if_in_previous_week, check_if_in_thursday )
          url = "#{date}/#{file}#{date}.tbz"
        end
      when "incremental"
        if filedate == "current"
          date = date_to_epf_format( today, false, check_if_in_previous_week, check_if_in_thursday )
          url = "current/incremental/current/#{file}#{date}.tbz"
        else
          main_date = main_dir_name_by_date( filedate, true, check_if_in_previous_week, check_if_in_thursday )
          date = date_to_epf_format( filedate )
          url = "#{main_date}/incremental/#{date}/#{file}#{date}.tbz"
        end
      when "file"
        date = date_to_epf_format( filedate, false, check_if_in_previous_week, check_if_in_thursday )
        url = "#{file}#{date}.tbz"
      end
      
      # Return false if no url was suggested
      return nil if url.empty?
      
      # Check if url is ok to download
      url_to_check = full_url( url )
      unless is_file_exists( url_to_check )
        # Try to download it from the previous week's directory
        return get_date_file_name( type, file, filedate, true, check_if_in_thursday ) unless check_if_in_previous_week
        return get_date_file_name( type, file, filedate, false, true ) unless check_if_in_thursday

        # The EPF file was not found
        return nil
      end
      
      # it's ok to download this file
      url
    end
    
    private
    
    def is_file_exists(url)
      p "Checking file at URL: #{url}"
      
      uri = URI.parse( url )

      # do a head request
      http_request = Net::HTTP.new(uri.host, uri.port)
      # use SSL
      #  based on: http://stackoverflow.com/questions/8014291/making-http-head-request-with-timeout-in-ruby
      http_request.use_ssl = true
      # request.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
      p "starting head request..."
      response = http_request.start { |http|
        head_request = Net::HTTP::Head.new( url )
        head_request.basic_auth( AppleEpfImporter.configuration.apple_id, AppleEpfImporter.configuration.apple_password )
        
        http.request( head_request ) 
      }
      puts "response: #{response}"
      puts "response.code: #{response.code}"
      
      ( response.code == "200" )
    end
    
    def full_url( path )
      File.join( AppleEpfImporter.configuration.itunes_feed_url, path )
    end
    
    def main_dir_name_by_date(date, inc, in_previous_week, check_thursday )
      diff = check_thursday ? 4 : 3
    
      days_from_main = date.wday == diff ? 0 : diff - date.wday
      day_diff = days_from_main > 0 ? days_from_main - 7 : days_from_main
      date_of_file = date + day_diff
      date_of_file -= 7 if inc && date_of_file.to_date == date.to_date # The incremental file is stored in the previous dir...
      
      date_of_file -= 7 if in_previous_week
         
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
          curl.on_body { |data|
            f << data;
            data.size
          }
          curl.perform
        end
      rescue Curl::Err::PartialFileError => ex
        if @download_retry < 3
          @download_retry += 1
        
          p "Curl::Err::PartialFileError happened..."
          p "Restarting download"
          start_download( url, filename )
        else
          throw ex
        end
      end
    end
  end
end