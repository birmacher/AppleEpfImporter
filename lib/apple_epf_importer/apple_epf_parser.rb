module AppleEpfImporter
  class AppleEpfParser
    def parse(filename, header, row)    
      # Init defaults
      @field_separator = 1.chr
      @record_separator = 2.chr + "\n"
      @comment_char = '#'
      @header_info = Hash.new
      @footer_info = Hash.new
      @filename = filename
      
      parse_file
      # Header & footer
      if load_header_info
        header.call( @header_info )
      end
      close_file

      File.foreach( @filename, @record_separator ) do |line|
        unless line[0].chr == @comment_char
          line = line.chomp( @record_separator )

          row.call( line.split( @field_separator ) )
        end
      end
      
      @field_separator = nil
      @record_separator = nil
      @comment_char = nil
      @filename = nil
      
      @header_info.clear
      @header_info = nil
      @footer_info.clear
      @footer_info = nil
    end
    
    private
    
    def parse_file
      @file = File.new( @filename, 'r', encoding: 'UTF-8' )
    end
    
    def close_file
      @file.close if @file
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
      # File
      file_hash = { :file => File.basename( @filename ) }
      @header_info.merge! ( file_hash )
    
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
      
      # Records count
      @header_info.merge! ( load_footer_info )
    end
    
    def load_footer_info
      @file.seek(-40, IO::SEEK_END)
      records = @file.read.split( @comment_char ).last.chomp!( @record_separator ).sub( 'recordsWritten:', '' )
      records_hash = { :records => records }
      @footer_info.merge! ( records_hash )
      @file.rewind
      @footer_info
    end    
  end
end