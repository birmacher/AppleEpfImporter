module AppleEpfImporter
  class AppleEpfExtractor
  
    def extract(filename)
      files_to_extract = AppleEpfImporter.configuration.extractables
    
      files = Array.new
      files_to_extract.each do |f|
        files.push File.basename(filename, '.tbz') + '/' + f
      end
    
      system "cd #{AppleEpfImporter.configuration.extract_dir} && tar -xjf #{filename} #{files.join(' ')}"
    end
  end
end