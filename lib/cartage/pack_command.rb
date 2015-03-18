class Cartage
  class PackCommand < Command #:nodoc:
    def initialize(cartage)
      super(cartage, 'pack', takes_commands: false)

      Cartage.common_build_options(options, cartage)
      short_desc('Create a package with Cartage based on the Manifest.')
    end

    def perform
      @cartage.pack
    end
  end
end
