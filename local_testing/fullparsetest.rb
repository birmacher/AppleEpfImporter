#
# Helper for testing a full Apple EPF parsing 
#   - skips download and and extract, only does parsing
#
# Command line syntax:
#   ruby fullparsetest.rb
#   (where fullparsetest.rb is this script file)
#

require 'date'

require_relative '../lib/apple_epf_importer'

# args
extractdir_arg = nil
filename_date = Date.new( 2012, 10, 10 )
ARGV.each_with_index { |arg, argidx|
  puts " // given arg: '#{arg}'"
  if arg == '-exdir'
    extractdir_arg = ARGV[argidx+1]
  end
}

# arg validation
if extractdir_arg.nil?
  puts "[Error] No extract-to-dir argument found! (to specify use '-exdir the/path/to/extract/into' argument)"
  exit
end

# configure
AppleEpfImporter.configure do |config|
  config.itunes_files =     [ 'itunes', 'pricing' ]
  config.extractables =     [ 
    [ 'device_type', 'application_device_type', 'application', 'application_detail' ],
    [ 'application_price' ] 
  ]

  config.extract_dir =      extractdir_arg
end 

def header_parsed(header)
  puts "--header parsed"
end

def row_parsed(row)
  # print '.'
end

def parser_finished(success)
  puts "Finished: #{success}"
end

# --- start
puts "--parsing--"
parse_start_time = Time.now
AppleEpfImporter.test_parse_incremental( filename_date,
  lambda { |header| header_parsed( header ) },
  lambda { |row| row_parsed( row ) },
  lambda { |success| parser_finished( success ) } )
puts "--parsing[done]---"
puts "full parse time: #{Time.now - parse_start_time}"