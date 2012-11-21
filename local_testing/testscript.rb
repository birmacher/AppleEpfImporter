#
# Helper for testing a given Apple EPF file (not a complete 'tar' compressed file, 
#   but an uncompressed one, like 'application_detail')
# 
# This tester will parse the given EPF file and print out parsing statistics which can be
#   helpful during parsing optimization
#
# Command line syntax:
#   ruby testscript.rb -f the/path/to/the/epf/file
#   (where testscript.rb is this script file)
#

require_relative '../lib/apple_epf_importer/apple_epf_parser'

file_to_parse = nil
ARGV.each_with_index { |arg, argidx|
  puts " // given arg: '#{arg}'"
  if arg == '-f'
    file_to_parse = ARGV[argidx+1]
  end
}

# arg validation
if file_to_parse.nil?
  puts "[Error] No file-to-parse defined! (to specify use '-f the/path/to/the/file' argument)"
  exit
end

# configuration
## prints a '.' after every X row parsed
log_print_dot_after_rowcnt = 10000
## presents an intermediate statistic of the last X rows parsed + a total row parsed count
log_print_count_stat_and_time_after_rowcnt = 100000

# logging configs
puts " // file-to-parse: #{file_to_parse}"

def print_and_flush(str)
  print str
  # $stdout.flush
end

par = AppleEpfImporter::AppleEpfParser.new
# file_to_parse = '/home/viktorbenei/Dev/AppStream/apple_epf_importer/sampleinput/itunes20121010/application_detail'
# file_to_parse = '/Users/adminadmin/Dev/AppStream/Code/apple_epf_importer/sampleinput/application_price'
first_err = nil

time_start = Time.now
last_err_time = Time.now
last_err_measure_section_time = Time.now
err_parse_times = []
err_cnt = 0
par.parse(file_to_parse, 
  lambda{|h| 
    p h
  }, 
  lambda{|err|
    err_time = Time.now - last_err_time
    err_parse_times.push(err_time)
    last_err_time = Time.now
    first_err ||= err.clone
    err_cnt += 1
    if err_cnt%log_print_dot_after_rowcnt==0
      print_and_flush('.')
    end
    if err_cnt%log_print_count_stat_and_time_after_rowcnt==0
      print_and_flush("[#{err_cnt} : #{Time.now-last_err_measure_section_time}]")
      last_err_measure_section_time = Time.now
      puts
    end
  })
time_end = Time.now

puts
puts "--- statistics"
# puts "first err: #{first_err}"
puts "Full parse time: #{time_end - time_start}"
puts "Min err time: #{err_parse_times.min}"
puts "Max err time: #{err_parse_times.max}"
err_sorted = err_parse_times.sort
err_length = err_parse_times.length
median = err_length % 2 == 1 ? err_sorted[err_length/2] : (err_sorted[err_length/2 - 1] + err_sorted[err_length/2]).to_f / 2
puts "Median/mid err time: #{median}"
puts "Err cnt: #{err_cnt}"
# err_sorted[0..10].each do |rerrit|
#  puts "Test: #{rerrit}"
# end
puts "---"