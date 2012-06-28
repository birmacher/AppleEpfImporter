module AppleEpfImporter
  class AppleEpfExtractor
#     include Loggable
  
    def extract(filename)
      files_to_extract = AppleEpfImporter.configuration.extractables
    
      files = Array.new
      files_to_extract.each do |f|
        files.push File.basename(filename, '.tbz') + '/' + f
      end
    
      system 'tar --extract --file=' + filename + ' -C ' + AppleEpfImporter.configuration.extract_dir + ' ' + files.join(' ')
    end
  end
end