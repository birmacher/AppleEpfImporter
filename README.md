# AppleEpfImporter 

## Installation

    gem 'apple_epf_importer'

## Download incremental

    AppleEpfImporter.get_incremental( 'current',
                                      lambda { |header| puts header },
                                      lambda { |row| puts row },
                                      lambda { |success| puts 'Yeah!' if success } )

