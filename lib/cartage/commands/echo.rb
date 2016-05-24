# frozen_string_literal: true

##
# Call +extend+ Cartage::CLI to add the commands defined in the block.
Cartage::CLI.extend do
  desc 'Echo the provided text'
  arg :TEXT, :multiple
  command 'echo' do |echo|
    echo.hide!
    echo.desc 'Suppress newlines'
    echo.switch [ :c, 'no-newlines' ], negatable: false
    echo.action do |_g, options, args|
      unless cartage.quiet
        message = args.join(' ')
        if options['no-newlines'] || cartage.config(for_command: 'echo').no_newlines
          puts message
        else
          print message
        end
      end
    end
  end
end
