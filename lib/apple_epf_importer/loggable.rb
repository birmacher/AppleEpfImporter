require 'logger'

module Loggable
  def logger
    initialize_logger
  end
  
  private
  
  def initialize_logger
    begin
      Dir.mkdir('log') unless Dir.exists?('/log')
    rescue
      # Szar van a palacsintaban
    end
    
    logfile = File.open('log/apple_epf_importer.log', File::WRONLY | File::APPEND | File::CREAT)
    logger = Logger.new(logfile, 'weekly')
    logger.level = Logger::DEBUG
    logger
  end
end