module AppleEpfImporter
  class AppleEpfParser
  #   include Loggable
    
  #   def test(filename)
  #     parse( filename,
  #            lambda { |header| puts header },
  #            lambda { |footer| puts footer },
  #            lambda { |row| puts row['name'] } )
  #   end
    
    def parse(filename, header, footer, row)    
      # Init defaults
      @field_separator = 1.chr
      @record_separator = 2.chr + "\n"
      @comment_char = '#'
      @header_info = Hash.new
      @footer_info = Hash.new
          
      # Open file
      parse_file filename
      
      # Header
      if header_info = load_header_info
        header.call( header_info )
      end
        
      # Footer
      if footer_info = load_footer_info
        footer.call( footer_info )
      end
      
      # Load content
      until !(data = load_file_data)
        row.call( data )
      end
    end
    
    private
    
    def parse_file(filename)  
      @file = File.new( filename, 'r', encoding: 'UTF-8' )
    end
    
    def read_line(accept_comment = false)
      valid_line = false
      until valid_line
        begin
          line = @file.readline( @record_separator )
        rescue EOFError => e
          return nil
        end
        valid_line = accept_comment ? true : !line.start_with?( @comment_char )
      end
      line.sub!( @comment_char, '' ) if accept_comment
      line.chomp!( @record_separator )
    end
  
    def load_header_info    
      # Columns
      line = read_line(true)
      column_hash = { :columns => line.split( @field_separator ) }
      @header_info.merge! ( column_hash )
      
      # Primary keys
      line = read_line(true).sub!( 'primaryKey:', '' )
      primary_hash = { :primary_keys => line.split( @field_separator ) }
      @header_info.merge! ( primary_hash )
      
      # DB types
      line = read_line(true).sub!( 'dbTypes:', '' )
      primary_hash = { :db_types => line.split( @field_separator ) }
      @header_info.merge! ( primary_hash )
          
      # Export type
      line = read_line(true).sub!( 'exportMode:', '' )
      primary_hash = { :export_type => line.split( @field_separator ) }
      @header_info.merge! ( primary_hash )
    end
    
    def load_footer_info
      @file.seek(-40, IO::SEEK_END)
      records = @file.read.split( @comment_char ).last.chomp!( @record_separator ).sub( 'recordsWritten:', '' )
      records_hash = { :records => records }
      @footer_info.merge! ( records_hash )
      @file.rewind
      @footer_info
    end
    
    def load_file_data
      line = read_line
      return nil if line.nil?
      
      fields = line.split( @field_separator )
      row = Hash.new
      fields.each_with_index do |data, index|
        data_hash = { @header_info[:columns][index] => data }
        row.merge! ( data_hash )
      end
      row
    end
  end
end