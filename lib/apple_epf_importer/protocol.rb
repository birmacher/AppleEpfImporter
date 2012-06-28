module Net
  class BufferedIO
    # Change buffer size for better performance
    def rbuf_fill
      timeout(AppleEpfImporter.configuration.read_timeout) {
        @rbuf << @io.sysread(AppleEpfImporter.configuration.read_buffer_size)
      }
    end
  end
end