module AppleEpfImporter
  class AppleEpfExtractor
#     include Loggable
  
    def extract(filename)
      files_to_extract = AppleEpfImporter.configuration.extractables
    
      files = Array.new
      files_to_extract.each do |f|
        files.push File.basename(filename, '.tbz') + '/' + f
      end
    
      puts "cd #{AppleEpfImporter.configuration.extract_dir} && tar -xjf #{filename} #{files.join(' ')}"
      system "cd #{AppleEpfImporter.configuration.extract_dir} && tar -xjf #{filename} #{files.join(' ')}"
    end
  end
end